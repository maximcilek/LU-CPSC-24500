#!/usr/bin/env bash
set -euo pipefail

echo "[+] Installing Envoy proxy (Debian/Ubuntu compatible)..."

# -----------------------------
# Ensure we are on a Debian-based system
# -----------------------------
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "[!] Cannot detect OS (/etc/os-release missing)"
  exit 1
fi

if [[ "${ID}" != "ubuntu" && "${ID_LIKE:-}" != *"debian"* && "${ID}" != "debian" ]]; then
  echo "[!] Unsupported OS: ${ID}"
  echo "    This installer supports Debian/Ubuntu only."
  exit 1
fi

echo "[+] Detected OS: ${ID}"

# -----------------------------
# Get codename (jammy, noble, bookworm, etc.)
# -----------------------------
if command -v lsb_release >/dev/null 2>&1; then
  CODENAME="$(lsb_release -cs)"
else
  CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
fi

if [ -z "${CODENAME}" ]; then
  echo "[!] Could not determine distro codename"
  exit 1
fi

echo "[+] Distribution codename: ${CODENAME}"

# -----------------------------
# Architecture
# -----------------------------
ARCH="$(dpkg --print-architecture)"
echo "[+] Architecture: ${ARCH}"

# -----------------------------
# Keyring setup
# -----------------------------
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/envoy-keyring.gpg"

sudo mkdir -p "${KEYRING_DIR}"

if [ ! -f "${KEYRING_FILE}" ]; then
  echo "[+] Installing Envoy signing key..."
  curl -fsSL https://apt.envoyproxy.io/signing.key \
    | sudo gpg --dearmor -o "${KEYRING_FILE}"
else
  echo "[+] Key already exists, skipping"
fi

# -----------------------------
# Repo setup
# -----------------------------
REPO_FILE="/etc/apt/sources.list.d/envoy.list"

if [ ! -f "${REPO_FILE}" ]; then
  echo "[+] Adding Envoy APT repository..."
  echo "deb [arch=${ARCH} signed-by=${KEYRING_FILE}] https://apt.envoyproxy.io ${CODENAME} main" \
    | sudo tee "${REPO_FILE}" > /dev/null
else
  echo "[+] Repo already exists, skipping"
fi

# -----------------------------
# Install Envoy
# -----------------------------
echo "[+] Updating apt..."
sudo apt-get update -y

echo "[+] Installing Envoy..."
sudo apt-get install -y envoy

# -----------------------------
# Verify
# -----------------------------
echo "[+] Envoy version:"
envoy --version

echo "[✓] Envoy installation complete"