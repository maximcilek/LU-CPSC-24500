#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Load platform environment
# -----------------------------
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../config" && pwd)/platform.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] Missing env file: $ENV_FILE"
  exit 1
fi

echo "[+] Loaded env file from: $ENV_FILE"

set -a
source "$ENV_FILE"
set +a

# -----------------------------
# Required config
# -----------------------------
: "${CORE_DNS_CONTAINER_NAME:?Missing CORE_DNS_CONTAINER_NAME}"

echo "[+] Removing CoreDNS container..."

# Remove via nerdctl
sudo nerdctl rm -f "${CORE_DNS_CONTAINER_NAME}" 2>/dev/null || true

# Cleanup lingering containerd task (defensive)
echo "[+] Cleaning leftover containerd task (if any)..."
TASK_ID=$(sudo ctr tasks list | awk -v name="$CORE_DNS_CONTAINER_NAME" '$1 == name {print $1}' || true)

if [[ -n "${TASK_ID}" ]]; then
  sudo ctr tasks kill -s SIGKILL "${TASK_ID}" 2>/dev/null || true
  sudo ctr tasks rm "${TASK_ID}" 2>/dev/null || true
fi

# Cleanup lingering container metadata (defensive)
echo "[+] Cleaning leftover container metadata (if any)..."
CONTAINER_ID=$(sudo ctr containers list | awk -v name="$CORE_DNS_CONTAINER_NAME" '$1 == name {print $1}' || true)

if [[ -n "${CONTAINER_ID}" ]]; then
  sudo ctr containers rm "${CONTAINER_ID}" 2>/dev/null || true
fi

echo "[✓] CoreDNS removed"