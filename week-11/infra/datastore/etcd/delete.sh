#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------
# Resolve paths
# -------------------------------------------------
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../config" && pwd)/platform.env"

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
: "${ETCD_CONTAINER_NAME:?Missing ETCD_CONTAINER_NAME}"
: "${ETCD_DATA_DIR:?Missing ETCD_DATA_DIR}"

ETCD_SYSTEMD_SERVICE_NAME="${ETCD_SYSTEMD_SERVICE_NAME:-${ETCD_CONTAINER_NAME}.service}"
SERVICE_FILE="/etc/systemd/system/${ETCD_SYSTEMD_SERVICE_NAME}"

# SYSTEMD TEARDOWN
echo "[+] Stopping systemd service..."
sudo systemctl stop "$ETCD_SYSTEMD_SERVICE_NAME" 2>/dev/null || true

echo "[+] Disabling systemd service..."
sudo systemctl disable "$ETCD_SYSTEMD_SERVICE_NAME" 2>/dev/null || true

echo "[+] Removing systemd service file..."
if [[ -f "$SERVICE_FILE" ]]; then
  sudo rm -f "$SERVICE_FILE"
  echo "    removed: $SERVICE_FILE"
else
  echo "    service file not found: $SERVICE_FILE"
fi

echo "[+] Reloading systemd daemon..."
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

# CONTAINER CLEANUP
echo "[+] Stopping etcd (nerdctl)..."
sudo nerdctl rm -f "$ETCD_CONTAINER_NAME" 2>/dev/null || true

echo "[+] Killing containerd task (if still running)..."
TASK_ID=$(sudo ctr tasks list 2>/dev/null | awk '/etcd/ {print $1}' || true)
if [[ -n "${TASK_ID}" ]]; then
  sudo ctr tasks kill -s SIGKILL "$TASK_ID" 2>/dev/null || true
  sudo ctr tasks rm "$TASK_ID" 2>/dev/null || true
fi

echo "[+] Removing containerd container (if present)..."
CONTAINER_ID=$(sudo ctr containers list 2>/dev/null | awk '/etcd/ {print $1}' || true)
if [[ -n "${CONTAINER_ID}" ]]; then
  sudo ctr containers rm "$CONTAINER_ID" 2>/dev/null || true
fi

# -------------------------------------------------
# DATA CLEANUP
# -------------------------------------------------
echo "[+] Removing etcd data directory..."
sudo rm -rf "$ETCD_DATA_DIR" 2>/dev/null || true

echo "[+] Cleaning dangling snapshots..."
sudo ctr snapshots prune >/dev/null 2>&1 || true

echo "[✓] etcd fully stopped, disabled, service removed, and cleaned"