#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="registry"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SOURCE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/registry.service"

echo "[+] Installing systemd service: ${SERVICE_NAME}"

echo "[+] Copying service file to systemd..."
sudo cp "$SOURCE_FILE" "$SERVICE_FILE"

echo "[+] Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "[+] Enabling service (boot start)..."
sudo systemctl enable "$SERVICE_NAME"

echo "[+] Restarting service..."
sudo systemctl restart "$SERVICE_NAME"

echo "[+] Checking status..."
sudo systemctl --no-pager status "$SERVICE_NAME" || true

echo "[+] Recent logs:"
sudo journalctl -u "$SERVICE_NAME" -n 30 --no-pager