#!/usr/bin/env bash
set -euo pipefail

CONTAINERD_VERSION="2.2.3"


echo "[+] Starting containerd bootstrap..."

# -----------------------------
# Change tracking flags
# -----------------------------
SYSTEMD_CHANGED=0
CONFIG_CHANGED=0

# -----------------------------
# Locate repo root (no git dependency)
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/../../..")"

echo "Script Directory: ${SCRIPT_DIR}"
echo "Repo Root: ${REPO_ROOT}"

install_containerd() {
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "[ERROR] Unsupported arch: $ARCH" && exit 1 ;;
  esac

  TMP_DIR="$(mktemp -d)"

  # -----------------------------
  # Detect current version
  # -----------------------------
  CURRENT_VERSION="none"
  if command -v containerd >/dev/null 2>&1; then
    CURRENT_VERSION=$(containerd --version | awk '{print $3}' | sed 's/v//')
  fi

  echo "[+] Current containerd version: $CURRENT_VERSION"
  echo "[+] Desired containerd version: $CONTAINERD_VERSION"

  # -----------------------------
  # Skip if already correct version
  # -----------------------------
  if [[ "$CURRENT_VERSION" == "$CONTAINERD_VERSION" ]]; then
    echo "[✓] containerd already at desired version"
    return 0
  fi

  echo "[+] Installing/upgrading containerd..."

  # -----------------------------
  # Download tarball
  # -----------------------------
  curl -L \
    "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz" \
    -o "$TMP_DIR/containerd.tgz"

  # -----------------------------
  # Extract upgrade (overwrites binaries)
  # -----------------------------
  sudo tar -C /usr/local -xzf "$TMP_DIR/containerd.tgz"

  rm -rf "$TMP_DIR"

  echo "[✓] containerd installed/upgraded to v${CONTAINERD_VERSION}"
}

# =========================================================
# 2. APPLY SYSTEMD UNIT (diff-aware)
# =========================================================
apply_systemd_unit() {
  local SRC="$SCRIPT_DIR/containerd.service"
  local DST="/etc/systemd/system/containerd.service"

  echo "[+] Checking systemd unit..."

  if [[ ! -f "$SRC" ]]; then
    echo "[ERROR] Missing systemd unit: $SRC"
    exit 1
  fi

  if [[ ! -f "$DST" ]] || ! diff -q "$SRC" "$DST" >/dev/null; then
    echo "[+] Updating systemd unit..."

    sudo cp "$SRC" "$DST"
    sudo systemctl daemon-reload

    SYSTEMD_CHANGED=1
  else
    echo "[✓] systemd unit unchanged"
  fi
}

# =========================================================
# 3. APPLY CONTAINERD CONFIG (diff-aware)
# =========================================================
apply_containerd_config() {
  local SRC="$SCRIPT_DIR/config.toml"
  local DST="/etc/containerd/config.toml"

  echo "[+] Checking containerd config..."

  if [[ ! -f "$SRC" ]]; then
    echo "[ERROR] Missing config.toml: $SRC"
    exit 1
  fi

  sudo mkdir -p /etc/containerd

  if [[ ! -f "$DST" ]] || ! diff -q "$SRC" "$DST" >/dev/null; then
    echo "[+] Updating containerd config..."

    sudo cp "$SRC" "$DST"
    sudo chmod 644 "$DST"

    CONFIG_CHANGED=1
  else
    echo "[✓] containerd config unchanged"
  fi
}

# =========================================================
# 4. RESTART LOGIC (only if needed)
# =========================================================
restart_containerd_if_needed() {
  if [[ "$SYSTEMD_CHANGED" -eq 1 || "$CONFIG_CHANGED" -eq 1 ]]; then
    echo "[+] Restarting containerd (changes detected)..."
    sudo systemctl restart containerd
  else
    echo "[✓] No restart needed"
  fi
}

# =========================================================
# 5. VERIFY SERVICE
# =========================================================
verify_containerd() {
  echo "[+] Verifying containerd..."

  if systemctl is-active --quiet containerd; then
    echo "[✓] containerd is running"
  else
    echo "[ERROR] containerd failed to start"
    sudo journalctl -u containerd --no-pager -n 50
    exit 1
  fi
}

# =========================================================
# MAIN EXECUTION FLOW
# =========================================================
install_containerd
apply_systemd_unit
apply_containerd_config
restart_containerd_if_needed
verify_containerd

echo "[✓] containerd bootstrap complete"