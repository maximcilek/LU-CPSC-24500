#!/usr/bin/env bash
set -euo pipefail

NERDCTL_VERSION="1.7.6"   # you can bump this if needed
ARCH="amd64"

echo "[+] Installing nerdctl v${NERDCTL_VERSION}"

# -----------------------------
# Dependencies
# -----------------------------
sudo apt-get update -y
sudo apt-get install -y curl tar gzip

# -----------------------------
# Download nerdctl
# -----------------------------
TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR"

echo "[+] Downloading nerdctl..."
curl -L -o nerdctl.tar.gz \
  "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz"

tar -xzf nerdctl.tar.gz

echo "[+] Installing binary..."
sudo install -m 755 nerdctl /usr/local/bin/nerdctl

# -----------------------------
# Verify install
# -----------------------------
echo "[+] Verifying nerdctl..."
nerdctl version || true

# -----------------------------
# Optional: install buildkit (for build commands)
# -----------------------------
echo "[+] Installing buildkit (optional but recommended)..."

BUILDKIT_VERSION="0.13.2"

curl -L -o buildkit.tar.gz \
  "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-${ARCH}.tar.gz"

tar -xzf buildkit.tar.gz

sudo install -m 755 bin/buildctl /usr/local/bin/buildctl
sudo install -m 755 bin/buildkitd /usr/local/bin/buildkitd

echo "[+] Done."

# -----------------------------
# Final check
# -----------------------------
echo "[✓] nerdctl installed:"
which nerdctl

echo ""
echo "[✓] Test command:"
echo "  sudo nerdctl run --rm alpine ip a"