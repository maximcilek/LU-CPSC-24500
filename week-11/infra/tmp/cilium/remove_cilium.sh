#!/usr/bin/env bash
set -euo pipefail

echo "[!] WARNING: This will completely remove Cilium and all its networking state"
echo "[!] Press Ctrl+C to cancel, or Enter to continue"
read

# =========================================================
# STOP ANY CILIUM PROCESSES
# =========================================================
echo "[+] Stopping Cilium processes..."

sudo pkill -f cilium-agent 2>/dev/null || true
sudo pkill -f cilium-envoy 2>/dev/null || true
sudo pkill -f cilium-operator 2>/dev/null || true
sudo pkill -f hubble 2>/dev/null || true

# =========================================================
# DELETE CILIUM CLI
# =========================================================
echo "[+] Removing Cilium CLI..."
sudo rm -f /usr/local/bin/cilium

# =========================================================
# REMOVE CNI CONFIGS
# =========================================================
echo "[+] Removing CNI configs..."
sudo rm -f /etc/cni/net.d/*cilium* 2>/dev/null || true
sudo rm -f /etc/cni/net.d/05-cilium* 2>/dev/null || true
sudo rm -f /etc/cni/net.d/10-cilium* 2>/dev/null || true

# =========================================================
# REMOVE CNI STATE (CRITICAL)
# =========================================================
echo "[+] Removing CNI state..."
sudo rm -rf /var/lib/cni/networks/cilium* 2>/dev/null || true
sudo rm -rf /var/run/cilium 2>/dev/null || true
sudo rm -rf /var/run/containers/cilium 2>/dev/null || true

# =========================================================
# REMOVE BPF FS STATE
# =========================================================
echo "[+] Unmounting and cleaning BPF filesystem..."

sudo umount /sys/fs/bpf 2>/dev/null || true
sudo rm -rf /sys/fs/bpf/* 2>/dev/null || true

# =========================================================
# REMOVE CILIUM NETWORK INTERFACES
# =========================================================
echo "[+] Removing network interfaces..."

sudo ip link delete cilium_host 2>/dev/null || true
sudo ip link delete cilium_net 2>/dev/null || true
sudo ip link delete cilium_vxlan 2>/dev/null || true
sudo ip link delete cilium_geneve 2>/dev/null || true
sudo ip link delete cni-br0 2>/dev/null || true

# =========================================================
# CLEAN IPTABLES RULES (CILIUM CHAINS)
# =========================================================
echo "[+] Cleaning iptables rules..."

sudo iptables-save | grep -v CILIUM | sudo iptables-restore 2>/dev/null || true

# brute-force cleanup (fallback safety)
sudo iptables -F CILIUM_OUTPUT 2>/dev/null || true
sudo iptables -F CILIUM_INPUT 2>/dev/null || true
sudo iptables -F CILIUM_FORWARD 2>/dev/null || true

sudo iptables -X CILIUM_OUTPUT 2>/dev/null || true
sudo iptables -X CILIUM_INPUT 2>/dev/null || true
sudo iptables -X CILIUM_FORWARD 2>/dev/null || true

# NAT cleanup
sudo iptables -t nat -F 2>/dev/null || true

# =========================================================
# CLEAN SYSTEM CONFIG (optional but safe)
# =========================================================
echo "[+] Cleaning sysctl overrides (if any)..."

sudo sysctl -w net.ipv4.ip_forward=0 >/dev/null || true

# =========================================================
# REMOVE LEFTOVER STATE DIRS
# =========================================================
echo "[+] Removing leftover directories..."

sudo rm -rf /var/lib/cilium 2>/dev/null || true
sudo rm -rf /etc/cilium 2>/dev/null || true
sudo rm -rf /var/log/cilium* 2>/dev/null || true

# =========================================================
# VERIFY CLEANUP
# =========================================================
echo "[+] Verification..."

if command -v cilium >/dev/null 2>&1; then
  echo "[!] Cilium CLI still present"
else
  echo "[✓] Cilium CLI removed"
fi

echo "[+] Remaining CNI configs:"
ls /etc/cni/net.d 2>/dev/null || echo "none"

echo "[✓] Cilium fully removed from system"