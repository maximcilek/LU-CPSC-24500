#!/usr/bin/env bash
set -euo pipefail

install_cni_plugins() {

  CNI_PLUGINS_VERSION="${CNI_PLUGINS_VERSION:-1.9.1}"
  CPU_ARCH="$(uname -m)"

  case "$CPU_ARCH" in
    x86_64) CPU_ARCH="amd64" ;;
    aarch64|arm64) CPU_ARCH="arm64" ;;
    *) echo "[!] Unsupported arch: $CPU_ARCH" && exit 1 ;;
  esac

  CNI_BIN_DIR="/opt/cni/bin"
  VERSION_FILE="$CNI_BIN_DIR/.cni-version"
  TMP_DIR="$(mktemp -d)"

  echo "[+] Forcing install of CNI plugins v${CNI_PLUGINS_VERSION}"

  sudo mkdir -p "$CNI_BIN_DIR"

  # -----------------------------
  # Download new version (ALWAYS)
  # -----------------------------
  echo "[+] Downloading CNI plugins..."

  curl -L -o "$TMP_DIR/cni.tgz" \
    "https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${CPU_ARCH}-v${CNI_PLUGINS_VERSION}.tgz"

  # -----------------------------
  # Extract
  # -----------------------------
  STAGING_DIR="$TMP_DIR/staging"
  mkdir -p "$STAGING_DIR"

  tar -C "$STAGING_DIR" -xzf "$TMP_DIR/cni.tgz"

  # -----------------------------
  # HARD REPLACE (no version logic)
  # -----------------------------
  echo "[+] Overwriting /opt/cni/bin..."

  sudo rm -rf "$CNI_BIN_DIR"
  sudo mkdir -p "$CNI_BIN_DIR"
  sudo cp -a "$STAGING_DIR/." "$CNI_BIN_DIR"

  # -----------------------------
  # Validate
  # -----------------------------
  if [[ ! -f "$CNI_BIN_DIR/loopback" ]]; then
    echo "[ERROR] CNI install failed"
    exit 1
  fi

  # -----------------------------
  # Force version write
  # -----------------------------
  echo "$CNI_PLUGINS_VERSION" | sudo tee "$VERSION_FILE" >/dev/null

  rm -rf "$TMP_DIR"

  echo "[✓] CNI plugins FORCE installed v${CNI_PLUGINS_VERSION}"
}

# =========================================================
# MAIN ENTRYPOINT
# =========================================================

install_cni_plugins