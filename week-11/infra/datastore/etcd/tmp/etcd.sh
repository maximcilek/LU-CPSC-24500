#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------
# Load shared platform config
# -------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# source shared config
source "$PROJECT_ROOT/infra/config/platform.env"

# -------------------------------------------------
# Validate required env vars
# -------------------------------------------------
: "${NETWORK_NAME:?Missing NETWORK_NAME in platform.env}"
: "${ETCD_IMAGE:?Missing ETCD_IMAGE in platform.env}"
: "${ETCD_CLIENT_PORT:?Missing ETCD_CLIENT_PORT in platform.env}"
: "${ETCD_PEER_PORT:?Missing ETCD_PEER_PORT in platform.env}"
: "${ETCD_HOST:=etcd}"
: "${ETCD_NAME:=etcd-1}"

echo "[+] Starting etcd container..."

# -------------------------------------------------
# Cleanup old container
# -------------------------------------------------
sudo nerdctl rm -f "$ETCD_HOST" 2>/dev/null || true

# -------------------------------------------------
# Start etcd using config values
# -------------------------------------------------
sudo nerdctl run -d \
  --name "$ETCD_HOST" \
  --net "$NETWORK_NAME" \
  -p "${ETCD_CLIENT_PORT}:${ETCD_CLIENT_PORT}" \
  -p "${ETCD_PEER_PORT}:${ETCD_PEER_PORT}" \
  "$ETCD_IMAGE" \
  /usr/local/bin/etcd \
  --name "$ETCD_NAME" \
  --data-dir /etcd-data \
  --listen-client-urls "http://0.0.0.0:${ETCD_CLIENT_PORT}" \
  --advertise-client-urls "http://0.0.0.0:${ETCD_CLIENT_PORT}" \
  --listen-peer-urls "http://0.0.0.0:${ETCD_PEER_PORT}" \
  --initial-advertise-peer-urls "http://0.0.0.0:${ETCD_PEER_PORT}" \
  --initial-cluster "${ETCD_NAME}=http://0.0.0.0:${ETCD_PEER_PORT}" \
  --initial-cluster-state new

echo "[✓] etcd running on:"
echo "    client API: ${ETCD_CLIENT_PORT}"
echo "    peer traffic: ${ETCD_PEER_PORT}"
echo "    network: ${NETWORK_NAME}"