#!/usr/bin/env bash
set -euo pipefail

cleanup() {
    if [[ -n "${PW_FILE:-}" && -f "$PW_FILE" ]]; then
        echo "[*] Cleaning up sensitive password file..."
        shred -u "$PW_FILE" 2>/dev/null || rm -f "$PW_FILE"
    fi
}

trap cleanup EXIT INT TERM

# -------------------------------------------------
# Paths
# -------------------------------------------------
# ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../config" && pwd)/platform.env"
ENV_FILE="/home/mcilek/Github/maximcilek/LU-CPSC-24500/week-11/infra/config/platform.env"
echo "[+] Loading env file: $ENV_FILE"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] Missing env file"
  exit 1
fi
set -a
source "$ENV_FILE"
set +a

# -------------------------------------------------
# Required config
# -------------------------------------------------
: "${STEP_CA_IMAGE:?Missing STEP_CA_IMAGE}"
: "${STEP_CA_CONTAINER_NAME:=step-ca}"
: "${STEP_CA_ADVERTISED_HOSTNAME:=step-ca}"
: "${STEP_CA_USER:=step}"
: "${STEP_CA_PORT:=9000}"
: "${NETWORK_NAME:?Missing NETWORK_NAME}"
: "${STEP_CA_DATA_DIR:-/var/lib/step-ca}"
echo "[+] Installing Step-CA (production hardened)"
echo "    image                 : $STEP_CA_IMAGE"
echo "    container name        : $STEP_CA_CONTAINER_NAME"
echo "    advertised hostname   : $STEP_CA_ADVERTISED_HOSTNAME"
echo "    port                  : $STEP_CA_PORT"
echo "    data                  : $STEP_CA_DATA_DIR"


if sudo nerdctl ps -a --format '{{.Names}}' | grep -q "^step-ca$"; then
  echo "[+] Container exists — starting instead of creating"
  # sudo nerdctl start step-ca
  sudo nerdctl container stop step-ca
  sudo nerdctl container rm step-ca
  exit 1
else
  echo "[+] Starting Step-CA runtime"

  # Decrypt Sealed CA Password
  PW_FILE="$(mktemp)"
  chmod 600 "$PW_FILE"
  echo "[+] Unsealing CA password from TPM into temp file: ${PW_FILE}"
  HANDLE=$(sudo tpm2_getcap handles-persistent | awk 'NR==1{print $2}') # STEP_CA_PASSWORD="$(tpm2_unseal -c "${HANDLE}" -p pcr:sha256:0,1,2,3)"
  printf '%s' "$(tpm2_unseal -c ${HANDLE} -p pcr:sha256:0,1,2,3)" > "$PW_FILE"
  chown  1000:1000 "${PW_FILE}"
  echo "[+] Unsealed CA password stored temporarily at: $PW_FILE"

  # Start container (runtime only, no init flags!)
  exec sudo nerdctl run \
    --name step-ca \
    --net "$NETWORK_NAME" \
    -p 9000:9000 \
    -v /var/lib/step-ca/certs:/home/step/certs \
    -v /var/lib/step-ca/config:/home/step/config \
    -v /var/lib/step-ca/db:/home/step/db \
    -v /var/lib/step-ca/templates:/home/step/templates \
    -v /var/lib/step-ca/secrets:/home/step/secrets \
    --tmpfs /run/secrets:rw,noexec,nosuid,size=10m \
    -v "$PW_FILE:/run/secrets/password:ro" \
    -e DOCKER_STEPCA_INIT_PASSWORD_FILE=/run/secrets/password \
    "$STEP_CA_IMAGE"
fi