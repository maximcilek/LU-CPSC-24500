#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------
# Resolve paths
# -------------------------------------------------
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

# -------------------------------------------------
# REQUIRED CONFIG
# -------------------------------------------------
: "${NETWORK_NAME:?Missing NETWORK_NAME}"
: "${ETCD_CONTAINER_NAME:?Missing ETCD_CONTAINER_NAME}"
: "${ETCD_IMAGE:?Missing ETCD_IMAGE}"
: "${ETCD_CLIENT_PORT:?Missing ETCD_CLIENT_PORT}"
: "${ETCD_PEER_PORT:?Missing ETCD_PEER_PORT}"
: "${ETCD_METRICS_PORT:?Missing ETCD_METRICS_PORT}"
: "${ETCD_DATA_DIR:?Missing ETCD_DATA_DIR}"
: "${ETCD_ADVERTISE_FQDN:?Missing ETCD_ADVERTISE_FQDN}"
: "${ETCD_NODE_NAME:?Missing ETCD_NAME}"
ETCD_SYSTEMD_UNIT_NAME="${ETCD_SYSTEMD_UNIT_NAME:-${ETCD_CONTAINER_NAME}.service}"
ETCD_SYSTEMD_UNIT_FILE="${ETCD_SYSTEMD_UNIT_FILE:-/etc/systemd/system/${ETCD_SYSTEMD_UNIT_NAME}}"
# how services reach etcd (IMPORTANT: must be reachable inside network)

# persistence on host
echo "[+] Installing etcd systemd service..."
echo "    network        : $NETWORK_NAME"
echo "    container name : $ETCD_CONTAINER_NAME"
echo "    node name      : $ETCD_NODE_NAME"
echo "    image          : $ETCD_IMAGE"
echo "    client port    : $ETCD_CLIENT_PORT"
echo "    peer port      : $ETCD_PEER_PORT"
echo "    metrics port   : $ETCD_METRICS_PORT"
echo "    advertise FQDN : $ETCD_ADVERTISE_FQDN"
echo "    data dir       : $ETCD_DATA_DIR"
echo "    systemd unit   : $ETCD_SYSTEMD_UNIT_FILE"

# Ensure persistence directory exists
sudo mkdir -p "$ETCD_DATA_DIR"
sudo chmod 700 "$ETCD_DATA_DIR"

# Stop old instances cleanly (avoid duplicates)
sudo systemctl stop "${ETCD_SYSTEMD_UNIT_NAME}" 2>/dev/null || true
sudo nerdctl rm -f "${ETCD_CONTAINER_NAME}" 2>/dev/null || true

# -------------------------------------------------
# Write systemd unit
# -------------------------------------------------
sudo tee "$ETCD_SYSTEMD_UNIT_FILE" >/dev/null <<EOF
[Unit]
Description=etcd (containerd runtime)
After=network.target containerd.service
Requires=containerd.service

[Service]
Type=simple
Restart=always
RestartSec=5

ExecStart=/usr/bin/env nerdctl run --rm \\
  --name ${ETCD_CONTAINER_NAME} \\
  --net ${NETWORK_NAME} \\
  -p ${ETCD_PEER_PORT}:${ETCD_PEER_PORT} \\
  -p ${ETCD_METRICS_PORT}:${ETCD_METRICS_PORT} \\
  -v ${ETCD_DATA_DIR}:/etcd-data \\
  ${ETCD_IMAGE} \\
  /usr/local/bin/etcd \\
  --name ${ETCD_NODE_NAME} \\
  --data-dir /etcd-data \\
  --listen-client-urls http://0.0.0.0:${ETCD_CLIENT_PORT} \\
  --advertise-client-urls http://${ETCD_ADVERTISE_FQDN}:${ETCD_CLIENT_PORT} \\
  --listen-metrics-urls=http://127.0.0.1:${ETCD_METRICS_PORT} \\
  --listen-peer-urls http://0.0.0.0:${ETCD_PEER_PORT} \\
  --initial-advertise-peer-urls http://${ETCD_ADVERTISE_FQDN}:${ETCD_PEER_PORT} \\
  --initial-cluster ${ETCD_NODE_NAME}=http://${ETCD_ADVERTISE_FQDN}:${ETCD_PEER_PORT} \\
  --initial-cluster-state new

ExecStop=/usr/bin/nerdctl stop ${ETCD_CONTAINER_NAME}

# Safety: avoid zombie containers on crash
ExecStopPost=/usr/bin/nerdctl rm -f ${ETCD_CONTAINER_NAME}

LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
EOF

# -------------------------------------------------
# Reload systemd + enable + restart
# -------------------------------------------------
sudo systemctl daemon-reload
sudo systemctl enable "${ETCD_SYSTEMD_UNIT_NAME}"
sudo systemctl restart "${ETCD_SYSTEMD_UNIT_NAME}"

# -------------------------------------------------
# Status
# -------------------------------------------------
echo "[✓] etcd service installed and running"
sudo systemctl --no-pager status "${ETCD_SYSTEMD_UNIT_NAME}" || true