#!/usr/bin/env bash
set -euo pipefail

if systemctl is-active --quiet step-ca; then
  echo "[!] step-ca already running — skipping bootstrap"
  exit 0
fi

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

cleanup() {
    if [[ -n "${PW_FILE:-}" && -f "$PW_FILE" ]]; then
        echo "[*] Cleaning up sensitive password file..."
        shred -u "$PW_FILE" 2>/dev/null || rm -f "$PW_FILE"
    fi
}

trap cleanup EXIT INT TERM

# System user
if ! id "${STEP_CA_USER}" &>/dev/null; then
  echo "[+] Creating system user: ${STEP_CA_USER}"
  sudo useradd --system --no-create-home --shell /usr/sbin/nologin "${STEP_CA_USER}"
fi

# -------------------------------------------------
# Create directories - Container runs as uid 1000 ("step")
# -------------------------------------------------
sudo mkdir -p "${STEP_CA_DATA_DIR}"
sudo mkdir -p "${STEP_CA_DATA_DIR}/certs" "${STEP_CA_DATA_DIR}/config" "${STEP_CA_DATA_DIR}/db" "${STEP_CA_DATA_DIR}/templates" "${STEP_CA_DATA_DIR}/secrets"
sudo chown -R 1000:1000 "${STEP_CA_DATA_DIR}"
sudo chmod 700 "${STEP_CA_DATA_DIR}"

echo "[+] Step-CA not initialized"
# Decrypt Sealed CA Password
PW_FILE="$(mktemp)"
chmod 600 "$PW_FILE"
echo "[+] Unsealing CA password from TPM into temp file: ${PW_FILE}"
HANDLE=$(sudo tpm2_getcap handles-persistent | awk 'NR==1{print $2}') # STEP_CA_PASSWORD="$(tpm2_unseal -c "${HANDLE}" -p pcr:sha256:0,1,2,3)"
printf '%s' "$(tpm2_unseal -c ${HANDLE} -p pcr:sha256:0,1,2,3)" > "$PW_FILE"
chown  1000:1000 "${PW_FILE}"
echo "[+] Unsealed CA password stored temporarily at: $PW_FILE"

# Bootstrap CA (ONLY ONCE)
echo "[+] Generating Step-CA configuration file(s)"
sudo nerdctl run -d \
    --name "step-ca" \
    --net "$NETWORK_NAME" \
    -v "$STEP_CA_DATA_DIR/certs:/home/step/certs" \
    -v "$STEP_CA_DATA_DIR/config:/home/step/config" \
    -v "$STEP_CA_DATA_DIR/db:/home/step/db" \
    -v "$STEP_CA_DATA_DIR/templates:/home/step/templates" \
    -v "$STEP_CA_DATA_DIR/secrets:/home/step/secrets" \
    --tmpfs /run/secrets:rw,noexec,nosuid,size=10m \
    -v "$PW_FILE:/run/secrets/password:ro" \
    -e DOCKER_STEPCA_INIT_NAME="Maxim Cilek CA" \
    -e "DOCKER_STEPCA_INIT_DNS_NAMES=localhost,${STEP_CA_ADVERTISED_HOSTNAME},$(hostname -f)" \
    -e DOCKER_STEPCA_INIT_PASSWORD_FILE="/run/secrets/password" \
    -e DOCKER_STEPCA_INIT_WITH_CA_URL="https://${STEP_CA_ADVERTISED_HOSTNAME}:${STEP_CA_PORT}" \
    -e "DOCKER_STEPCA_INIT_DEPLOYMENT_TYPE=standalone" \
    -e DOCKER_STEPCA_INIT_ACME=true \
    -e DOCKER_STEPCA_INIT_PROVISIONER_NAME="admin" \
    -e DOCKER_STEPCA_INIT_ADMIN_SUBJECT="step" \
    -e DOCKER_STEPCA_INIT_ADDRESS=":${STEP_CA_PORT}" \
    -p 9000:9000 \
    "$STEP_CA_IMAGE"

until curl -k https://localhost:9000/health; do
    sleep 0.5
done
echo "[+] Successfully created Step-CA configuration file(s): ${STEP_CA_DATA_DIR}"
echo "[✓] CA is ready"
echo "[+] Shredding temporary CA password file on local machine"
shred -u "$PW_FILE"
echo "[+] Successfully shredded temporary CA password file"
sudo nerdctl container stop step-ca
sudo nerdctl container rm step-ca

# #!/usr/bin/env bash
# set -euo pipefail
# 
# echo "[+] Bootstrapping Step-CA"
# 
# PW_FILE="$(mktemp)"
# chmod 600 "$PW_FILE"
# 
# HANDLE=$(sudo tpm2_getcap handles-persistent | awk 'NR==1{print $2}')
# 
# sudo tpm2_unseal \
#   -c "$HANDLE" \
#   -p pcr:sha256:0,1,2,3 \
#   > "$PW_FILE"
# 
# sudo nerdctl run --rm \
#   -v /var/lib/step-ca:/home/step \
#   --tmpfs /run/secrets \
#   -v "$PW_FILE:/run/secrets/password:ro" \
#   -e DOCKER_STEPCA_INIT_PASSWORD_FILE=/run/secrets/password \
#   -e DOCKER_STEPCA_INIT_NAME="Maxim Cilek CA" \
#   -e DOCKER_STEPCA_INIT_DNS_NAMES="localhost,step-ca,$(hostname -f)" \
#   -e DOCKER_STEPCA_INIT_PROVISIONER_NAME="admin" \
#   -e DOCKER_STEPCA_INIT_ADDRESS=":9000" \
#   smallstep/step-ca:0.30.2
# 
# shred -u "$PW_FILE"
# echo "[✓] Bootstrap complete"
