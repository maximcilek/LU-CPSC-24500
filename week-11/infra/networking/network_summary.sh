#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[+] Script Directory: $SCRIPT_DIR"

# -----------------------------
# Config
# -----------------------------
OUT_DIR="${OUT_DIR:-/home/mcilek/Github/maximcilek/LU-CPSC-24500/week-11/data/_meta/network-snapshots}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
HOST="$(hostname -s)"
OUT_FILE="${OUT_DIR}/network-${HOST}-${TIMESTAMP}.log"

mkdir -p "$OUT_DIR"

echo "[+] Writing network snapshot to: $OUT_FILE"

# -----------------------------
# Header
# -----------------------------
{
echo "============================================================"
echo " NETWORK SNAPSHOT (containerd + CNI)"
echo " Host:        $HOST"
echo " Timestamp:   $TIMESTAMP"
echo " Kernel:      $(uname -r)"
echo " Arch:        $(uname -m)"
echo "============================================================"
echo ""
} > "$OUT_FILE"

# -----------------------------
# Interfaces
# -----------------------------
{
echo "====================[ INTERFACES ]=========================="
ip link show
echo ""
} >> "$OUT_FILE"

# -----------------------------
# IP addresses
# -----------------------------
{
echo "====================[ IP ADDRESSES ]========================"
ip addr show
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Routing table
# -----------------------------
{
echo "====================[ ROUTES ]==============================="
ip route show
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Network namespaces (container isolation view)
# -----------------------------
{
echo "====================[ NETWORK NAMESPACES ]==================="
ip netns list || echo "No netns configured"
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Container interfaces (veth, ipvlan, bridge)
# -----------------------------
{
echo "====================[ CONTAINER NETWORK LINKS ]============="
echo "[veth / bridge / ipvlan interfaces]"
ip link show type veth 2>/dev/null || true
ip link show type bridge 2>/dev/null || true
ip link show type ipvlan 2>/dev/null || true
echo ""
} >> "$OUT_FILE"

# -----------------------------
# ARP / neighbor table
# -----------------------------
{
echo "====================[ NEIGHBORS ]============================"
ip neigh show || true
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Sockets
# -----------------------------
{
echo "====================[ SOCKETS ]=============================="
ss -tulpen || true
echo ""
} >> "$OUT_FILE"

# -----------------------------
# iptables rules (CNI NAT visibility)
# -----------------------------
{
echo "====================[ IPTABLES FILTER ]======================"
iptables -L -n -v 2>/dev/null || echo "iptables not available"
echo ""
echo "====================[ IPTABLES NAT ]========================="
iptables -t nat -L -n -v 2>/dev/null || echo "iptables NAT not available"
echo ""
} >> "$OUT_FILE"

# -----------------------------
# CNI configuration inspection
# -----------------------------
{
echo "====================[ CNI CONFIG ]==========================="
ls -l /etc/cni/net.d 2>/dev/null || echo "No CNI config directory"
echo ""

echo "--- active CNI configs ---"
cat /etc/cni/net.d/*.conf 2>/dev/null || true
cat /etc/cni/net.d/*.conflist 2>/dev/null || true
echo ""
} >> "$OUT_FILE"

# -----------------------------
# CNI binaries
# -----------------------------
{
echo "====================[ CNI BINARIES ]========================="
ls -l /opt/cni/bin 2>/dev/null || echo "No CNI binaries found"
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Container runtime hints (containerd)
# -----------------------------
{
echo "====================[ CONTAINERD STATE ]====================="
command -v ctr >/dev/null 2>&1 && ctr containers ls || echo "ctr not installed or not in PATH"
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Summary
# -----------------------------
{
echo "====================[ SUMMARY NOTES ]========================"
echo "Key things to inspect:"
echo " - bridge: cni-br0 (if using bridge CNI)"
echo " - ipvlan: direct NIC attachment (no bridge)"
echo " - veth pairs (bridge mode only)"
echo " - NAT rules (iptables MASQUERADE)"
echo " - /etc/cni/net.d for active config"
echo ""
echo "Compare snapshots with:"
echo "  diff snapshot1.log snapshot2.log"
echo "============================================================"
} >> "$OUT_FILE"

echo "[✓] Snapshot complete: $OUT_FILE"