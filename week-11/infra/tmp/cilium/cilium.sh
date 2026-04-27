#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# CONFIG
# =========================================================
CILIUM_VERSION="1.19.3"

CNI_BIN_DIR="/opt/cni/bin"
CNI_CONF_DIR="/etc/cni/net.d"
INSTALL_DIR="/usr/local/bin"

# =========================================================
# ARCH DETECTION
# =========================================================
get_arch() {
  case "$(uname -m)" in
    x86_64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *)
      echo "[!] Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

ARCH="$(get_arch)"

# =========================================================
# TEMP DIR (safe + auto cleanup)
# =========================================================
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[+] Temp dir: $TMP_DIR"
echo "[+] Arch: $ARCH"

# =========================================================
# INSTALL CILIUM CLI
# =========================================================
install_cilium_cli() {
  if command -v cilium >/dev/null 2>&1; then
    echo "[✓] Cilium CLI already installed"
    return 0
  fi

  local CLI_VERSION
  CLI_VERSION="$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)"

  echo "[+] Installing Cilium CLI ${CLI_VERSION}"

  local BASE="https://github.com/cilium/cilium-cli/releases/download/${CLI_VERSION}"
  local FILE="cilium-linux-${ARCH}.tar.gz"

  (
    cd "$TMP_DIR"

    curl -L --fail --remote-name-all \
      "$BASE/$FILE" \
      "$BASE/$FILE.sha256sum"

    sha256sum --check "$FILE.sha256sum"

    tar -xzf "$FILE"

    sudo install -m 0755 cilium "$INSTALL_DIR/cilium"
  )

  echo "[✓] Cilium CLI installed"
}

# =========================================================
# INSTALL CILIUM (CNI MODE)
# =========================================================
install_cilium() {
  if cilium status >/dev/null 2>&1; then
    echo "[✓] Cilium already installed"
    return 0
  fi

  echo "[+] Installing Cilium ${CILIUM_VERSION}"

  sudo cilium install \
    --version "${CILIUM_VERSION}" \
    --datapath-mode veth \
    --set loadBalancer.acceleration=native \
    --set gatewayAPI.enabled=true \
    --set nodePort.enableHealthCheck=true \
    --set enableIPv4Masquerade=true \
    --set bpf.masquerade=true \
    --set routingMode=native \
    --set autoDirectNodeRoutes=true \
    --set ipam.mode=cluster-pool \
    --set ipam.operator.clusterPoolIPv4PodCIDRList="10.1.0.0/16" \
    --set ipv4NativeRoutingCIDR="10.1.0.0/16" \
    --set ipam.operator.clusterPoolIPv4MaskSize=24

  echo "[✓] Cilium installed"
}

# =========================================================
# VERIFY INSTALLATION
# =========================================================
verify() {
  echo "[+] Verifying installation..."

  echo ""
  cilium version || true
  echo ""

  echo "[+] CNI binaries:"
  ls -l "$CNI_BIN_DIR" 2>/dev/null | head || true

  echo ""
  echo "[+] CNI config:"
  ls -l "$CNI_CONF_DIR" 2>/dev/null || true
}

# =========================================================
# MAIN
# =========================================================
main() {
  sudo mkdir -p "$CNI_BIN_DIR" "$CNI_CONF_DIR"

  install_cilium_cli
  install_cilium
  verify

  echo "[✓] Cilium bootstrap complete"
}

main