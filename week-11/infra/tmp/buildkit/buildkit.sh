#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config
# -----------------------------
BUILDKIT_VERSION="${BUILDKIT_VERSION:-0.29.0}"
INSTALL_DIR="/usr/local/bin"
TMP_DIR="$(mktemp -d)"
SYSTEMD_FILE="/etc/systemd/system/buildkit.service"
BUILDKIT_CONFIG="/etc/buildkit/buildkitd.toml"
LOCAL_CONFIG="$(dirname "$0")/buildkitd.toml"

echo "[+] Temp dir: $TMP_DIR"

# -----------------------------
# Detect arch
# -----------------------------
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported arch: $ARCH" && exit 1 ;;
esac

OS="linux"

# -----------------------------
# Resolve version
# -----------------------------
if [[ "$BUILDKIT_VERSION" == "latest" ]]; then
  echo "[+] Resolving latest BuildKit version..."
  BUILDKIT_VERSION="$(curl -fsSL https://api.github.com/repos/moby/buildkit/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f 4)"
fi

# Normalize version format
if [[ "$BUILDKIT_VERSION" != v* ]]; then
  BUILDKIT_VERSION="v${BUILDKIT_VERSION}"
fi

echo "[+] Installing BuildKit: ${BUILDKIT_VERSION}"

# -----------------------------
# Download
# -----------------------------
TARBALL="buildkit-${BUILDKIT_VERSION}.${OS}-${ARCH}.tar.gz"
URL="https://github.com/moby/buildkit/releases/download/${BUILDKIT_VERSION}/${TARBALL}"

echo "[+] Downloading: $URL"
curl -L "$URL" -o "$TMP_DIR/buildkit.tar.gz"

# -----------------------------
# Extract
# -----------------------------
tar -C "$TMP_DIR" -xzf "$TMP_DIR/buildkit.tar.gz"

# -----------------------------
# Install binaries
# -----------------------------
sudo install -m 0755 "$TMP_DIR/bin/buildctl" "$INSTALL_DIR/buildctl"
sudo install -m 0755 "$TMP_DIR/bin/buildkitd" "$INSTALL_DIR/buildkitd"

rm -rf "$TMP_DIR"

echo "[+] Installed buildctl + buildkitd"

# -----------------------------
# Ensure containerd is available
# -----------------------------
if ! command -v containerd >/dev/null 2>&1; then
  echo "[!] containerd not found. Install containerd first."
  exit 1
fi

# -----------------------------
# Install BuildKit config (from local file)
# -----------------------------
if [[ ! -f "$LOCAL_CONFIG" ]]; then
  echo "[!] Missing local config: $LOCAL_CONFIG"
  exit 1
fi

echo "[+] Installing BuildKit config from $LOCAL_CONFIG"

sudo mkdir -p /etc/buildkit

sudo install -m 0644 \
  "$LOCAL_CONFIG" \
  "$BUILDKIT_CONFIG"

echo "[+] Config installed at $BUILDKIT_CONFIG"

# -----------------------------
# systemd service (production config)
# -----------------------------
echo "[+] Creating systemd service at $SYSTEMD_FILE"

sudo tee "$SYSTEMD_FILE" > /dev/null <<'EOF'
[Unit]
Description=BuildKit Daemon
After=network.target containerd.service
Requires=containerd.service

[Service]
Type=simple
ExecStart=/usr/local/bin/buildkitd \
  --addr unix:///run/buildkit/buildkitd.sock \
  --config /etc/buildkit/buildkitd.toml

Restart=always
RestartSec=2

# Security hardening (safe defaults for production)
NoNewPrivileges=true
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------
# Directories
# -----------------------------
sudo mkdir -p /var/lib/buildkit
sudo mkdir -p /run/buildkit

# -----------------------------
# Enable + start service
# -----------------------------
sudo systemctl daemon-reload
sudo systemctl enable buildkit
sudo systemctl restart buildkit

echo "[✓] BuildKit service started"

# -----------------------------
# Verify
# -----------------------------
buildctl --version || true
systemctl status buildkit --no-pager || true