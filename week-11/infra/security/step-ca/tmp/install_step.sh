#!/usr/bin/env bash
set -euo pipefail

STEP_VERSION_URL="https://github.com/smallstep/cli/releases/latest/download/step_linux_amd64.tar.gz"

TMP_DIR="$(mktemp -d)"
ARCHIVE="$TMP_DIR/step.tar.gz"
EXTRACT_DIR="$TMP_DIR/extracted"

echo "[+] Downloading Step CLI to /tmp"

curl -L "$STEP_VERSION_URL" -o "$ARCHIVE"

echo "[+] Extracting"
mkdir -p "$EXTRACT_DIR"
tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"

echo "[+] Installing binary"
sudo mv "$EXTRACT_DIR"/step_*/bin/step /usr/local/bin/

echo "[+] Setting permissions"
sudo chmod +x /usr/local/bin/step

echo "[+] Cleaning up"
rm -rf "$TMP_DIR"

echo "[✓] step installed successfully"
step version