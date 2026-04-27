#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Load platform environment
# -----------------------------
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../config" && pwd)/platform.env"
# Load environment
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] Missing env file: $ENV_FILE"
  exit 1
fi
echo "[+] Loaded env file from: $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

: "${CORE_DNS_CONTAINER_NAME:?Missing CORE_DNS_CONTAINER_NAME}"
: "${CORE_DNS_PORT:?Missing CORE_DNS_PORT}"
: "${CORE_DNS_IMAGE:?Missing CORE_DNS_IMAGE}"
: "${ETCD_ADVERTISE_FQDN:?Missing ETCD_ADVERTISE_FQDN}"
: "${ETCD_CLIENT_PORT:?Missing ETCD_CLIENT_PORT}"

CORE_DNS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_TEMPLATE_FILE="${CORE_DNS_DIR}/Corefile.template"
CORE_FILE="${CORE_DNS_DIR}/Corefile"

# Corefile Setup
envsubst < "${CORE_TEMPLATE_FILE}" > "${CORE_FILE}"
echo "[+] Validating Rendered CoreDNS Corefile"
if [[ ! -f "$CORE_FILE" ]]; then
  echo "[ERROR] Corefile not found at: $CORE_FILE"
  exit 1
fi

# -----------------------------
# Restart CoreDNS
# -----------------------------
echo "[+] Removing existing CoreDNS container..."
sudo nerdctl rm -f "${CORE_DNS_CONTAINER_NAME}" 2>/dev/null || true

echo "[+] Starting CoreDNS (etcd-backed)..."
sudo nerdctl run -d \
  --name "${CORE_DNS_CONTAINER_NAME} \
  --net "${NETWORK_NAME}" \
  -p "${CORE_DNS_PORT}:${CORE_DNS_PORT}/udp" \
  -p "${CORE_DNS_PORT}:${CORE_DNS_PORT}/tcp" \
  -v "$CORE_FILE:/Corefile:ro" \
  "${CORE_DNS_IMAGE}" \
  -conf /Corefile

echo "[✓] CoreDNS running (etcd-backed) on network: $NETWORK_NAME"