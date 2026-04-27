#!/usr/bin/env bash
set -euo pipefail

echo "User ID: $(id)"


# -------------------------------------------------
# Paths
# -------------------------------------------------
# ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../config" && pwd)/platform.env"

ENV_FILE="$(pwd)/infra/config/platform.env"
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
: "${NETWORK_NAME:?Missing NETWORK_NAME}"
: "${STEP_CA_CONTAINER_NAME:=step-ca}"
: "${STEP_CA_IMAGE:?Missing STEP_CA_IMAGE}"
: "${STEP_CA_FQDN:?Missing STEP_CA_FQDN}"
: "${STEP_CA_USER:=step}"
: "${STEP_CA_PORT:=9000}"
: "${STEP_CA_DATA_DIR:?Missing STEP_CA_DATA_DIR}"
echo "[+] Installing Step-CA (production hardened)"
echo "    network               : $NETWORK_NAME"
echo "    container name        : $STEP_CA_CONTAINER_NAME"
echo "    image                 : $STEP_CA_IMAGE"
echo "    fqdn                  : $STEP_CA_FQDN"
echo "    user                  : $STEP_CA_USER"
echo "    port                  : $STEP_CA_PORT"
echo "    data                  : $STEP_CA_DATA_DIR"

cleanup() {
    if [[ -n "${PW_FILE:-}" && -f "$PW_FILE" ]]; then
        echo "[*] Cleaning up sensitive password file..."
        shred -u "$PW_FILE" 2>/dev/null || rm -f "$PW_FILE"
    fi
}
trap cleanup EXIT INT TERM

if sudo nerdctl ps -f name=step-ca --format '{{.Names}}' | grep -q step-ca; then
  echo "[!] step-ca already running — skipping bootstrap"
  exit 0
fi

# System user
# if ! id "${STEP_CA_USER}" &>/dev/null; then
#   echo "[+] Creating system user: ${STEP_CA_USER}"
#   sudo useradd --system --no-create-home --shell /usr/sbin/nologin "${STEP_CA_USER}"
# fi
sudo mkdir -p "${STEP_CA_DATA_DIR}"
sudo mkdir -p "${STEP_CA_DATA_DIR}/certs" "${STEP_CA_DATA_DIR}/config" "${STEP_CA_DATA_DIR}/db" "${STEP_CA_DATA_DIR}/templates" "${STEP_CA_DATA_DIR}/secrets"
sudo chown -R ${STEP_CA_USER}:${STEP_CA_USER} "${STEP_CA_DATA_DIR}"
sudo chmod 700 "${STEP_CA_DATA_DIR}"

echo "[+] Step-CA not initialized"

# Decrypt Sealed CA Password
PW_FILE="$(mktemp)"
sudo chmod 600 "$PW_FILE"
printf '%s' "$(sudo tpm2_unseal -c $(sudo tpm2_getcap handles-persistent | awk 'NR==1{print $2}') -p pcr:sha256:0,1,2,3)" > "$PW_FILE"
sudo chown ${STEP_CA_USER}:${STEP_CA_USER} "$PW_FILE"
echo "[+] Unsealed CA password stored temporarily at: $PW_FILE"


# Bootstrap CA (ONLY ONCE)
echo "[+] Generating Step-CA configuration file(s) as ${STEP_CA_USER}"
sudo nerdctl run --rm \
    --name "${STEP_CA_CONTAINER_NAME}" \
    --net "$NETWORK_NAME" \
    --user ${STEP_CA_USER}:${STEP_CA_USER} \
    -v "$STEP_CA_DATA_DIR/certs:/home/step/certs" \
    -v "$STEP_CA_DATA_DIR/config:/home/step/config" \
    -v "$STEP_CA_DATA_DIR/db:/home/step/db" \
    -v "$STEP_CA_DATA_DIR/templates:/home/step/templates" \
    -v "$STEP_CA_DATA_DIR/secrets:/home/step/secrets" \
    --tmpfs /run/secrets:rw,noexec,nosuid,size=10m \
    -v "$PW_FILE:/run/secrets/password:ro" \
    -v "$(pwd)/infra/security/step-ca/entrypoint.sh:/entrypoint.sh:ro" \
    -e DOCKER_STEPCA_INIT_NAME="${STEP_CA_PKI_NAME}" \
    -e "DOCKER_STEPCA_INIT_DNS_NAMES=localhost,${STEP_CA_CONTAINER_NAME},${STEP_CA_FQDN},$(hostname -f)" \
    -e DOCKER_STEPCA_INIT_PASSWORD_FILE="/run/secrets/password" \
    -e DOCKER_STEPCA_INIT_WITH_CA_URL="https://${STEP_CA_FQDN}:${STEP_CA_PORT}" \
    -e "DOCKER_STEPCA_INIT_DEPLOYMENT_TYPE=${STEP_CA_DEPLOYMENT_TYPE}" \
    -e DOCKER_STEPCA_INIT_ACME=true \
    -e DOCKER_STEPCA_INIT_PROVISIONER_NAME="${STEP_CA_PROVISIONER_NAME}" \
    -e DOCKER_STEPCA_INIT_ADMIN_SUBJECT="${STEP_CA_ADMIN_SUBJECT}" \
    -e DOCKER_STEPCA_INIT_ADDRESS="${STEP_CA_FQDN}:${STEP_CA_PORT}" \
    -p ${STEP_CA_PORT}:${STEP_CA_PORT} \
    --entrypoint /entrypoint.sh \
    "$STEP_CA_IMAGE"

# until curl -k https://0.0.0.0:${STEP_CA_PORT}/health; do
#     sleep 0.5
# done
echo "[+] Shredding temporary CA password file on local machine"
shred -u "$PW_FILE"
echo "[+] Successfully shredded password"


sudo ls -l "${STEP_CA_DATA_DIR}"
#sudo chmod 600 "${STEP_CA_DATA_DIR}/secrets"/*
#sudo ls -l "${STEP_CA_DATA_DIR}/secrets"

# shred -u "run/secrets/password"
# echo "[+] Successfully shredded temporary CA password file"

echo "[+] Successfully created Step-CA configuration file(s): ${STEP_CA_DATA_DIR}"
echo "[✓] CA is ready"
# sudo nerdctl container stop step-ca
# sudo nerdctl container rm step-ca