#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="step-ca"

echo "[*] Checking for Step-CA container..."

if sudo nerdctl ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
    echo "[*] Stopping $CONTAINER_NAME..."
    sudo nerdctl stop "$CONTAINER_NAME" || true

    echo "[*] Removing $CONTAINER_NAME..."
    sudo nerdctl rm -f "$CONTAINER_NAME" || true

    echo "[+] Step-CA container stopped and removed."
else
    echo "[!] No Step-CA container found."
fi

sudo rm -rf /var/lib/step-ca/*
# sudo nerdctl exec -it step-ca /bin/bash