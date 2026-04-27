#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/aws.env"

# -------------------------------------------------
# Load environment
# -------------------------------------------------
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[ERROR] Missing env file: ${ENV_FILE}"
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

: "${AWS_ACCOUNT_ID:?Missing AWS_ACCOUNT_ID}"
: "${AWS_SSO_SESSION_NAME:?Missing AWS_SSO_SESSION_NAME}"
: "${AWS_SSO_START_URL:?Missing AWS_SSO_START_URL}"
: "${AWS_SSO_REGION:?Missing AWS_SSO_REGION}"
: "${AWS_SSO_REGISTRATION_SCOPES:?Missing AWS_SSO_REGISTRATION_SCOPES}"
: "${AWS_REGION:?Missing AWS_REGION}"
: "${AWS_SSO_ROLE_NAME:?Missing AWS_SSO_ROLE_NAME}"

AWS_OUTPUT="${AWS_OUTPUT:-json}"
AWS_PROFILE="${AWS_SSO_ROLE_NAME}-${AWS_ACCOUNT_ID}"
export AWS_PROFILE

# -------------------------------------------------
# AWS LOGIN CHECK
# -------------------------------------------------
check_login() {
  echo "[+] Checking AWS credentials..."

  if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "[✓] Already authenticated"
    return 0
  fi

  echo "[+] Logging in via AWS SSO..."
  aws sso login --profile "$AWS_PROFILE"
}

# -------------------------------------------------
# ROLE PROBE
# -------------------------------------------------
wait_for_role() {
  local role="$1"

  echo "[+] Waiting for role propagation: $role"

  for i in {1..10}; do
    if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
      echo "[✓] Role ready: $role"
      return 0
    fi
    sleep 2
  done

  echo "[ERROR] Role not available: $role"
  exit 1
}

# -------------------------------------------------
# CREATE ROLE (idempotent)
# -------------------------------------------------
create_role() {
  local role_name="$1"
  local trust_json="$2"

  if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
    echo "[✓] Role exists: $role_name"
    return 0
  fi

  echo "[+] Creating role: $role_name"

  aws iam create-role \
    --role-name "$role_name" \
    --assume-role-policy-document "$trust_json" >/dev/null

  wait_for_role "$role_name"
}

# -------------------------------------------------
# LOGIN
# -------------------------------------------------
check_login

echo "[+] Identity:"
aws sts get-caller-identity

# -------------------------------------------------
# BREAK GLASS ROLE (ADMIN LIFECYCLE ONLY)
# -------------------------------------------------
create_role "break-glass-admin" "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${AWS_ACCOUNT_ID}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
EOF
)"

aws iam put-role-policy \
  --role-name break-glass-admin \
  --policy-name break-glass-kms-secrets \
  --policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "KMSKeyAdminLifecycle",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:CreateAlias",
        "kms:Describe*",
        "kms:Enable*",
        "kms:Disable*",
        "kms:List*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerAdmin",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:PutSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:step-ca-*"
    }
  ]
}
EOF
)"

# -------------------------------------------------
# STEP CA RUNTIME ROLE (KMS CRYPTO ONLY)
# -------------------------------------------------
create_role "step-ca-admin" "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${AWS_ACCOUNT_ID}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)"

aws iam put-role-policy \
  --role-name step-ca-admin \
  --policy-name step-ca-kms-crypto \
  --policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "KMSCryptoOperations",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
    },
    {
      "Sid": "KMSGrantsForAWSResources",
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
EOF
)"

echo "[✓] Bootstrap complete"






echo "[+] Creating Step CA KMS key..."

KEY_ID=$(aws kms create-key \
  --description "Step CA symmetric encryption key for decrypting private keys" \
  --key-usage ENCRYPT_DECRYPT \
  --key-spec SYMMETRIC_DEFAULT \
  --query "KeyMetadata.KeyId" \
  --output text)

echo "[+] KMS Key created: $KEY_ID"

aws kms create-alias \
  --alias-name alias/step-ca \
  --target-key-id "$KEY_ID"

echo "[+] KMS Alias created: alias/step-ca"