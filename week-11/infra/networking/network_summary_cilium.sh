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
echo " NETWORK SNAPSHOT"
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
# Network namespaces
# -----------------------------
{
echo "====================[ NAMESPACES ]==========================="
ip netns list || echo "No network namespaces found or ip netns not configured"
echo ""
} >> "$OUT_FILE"

# -----------------------------
# ARP / Neighbor table
# -----------------------------
{
echo "====================[ NEIGHBORS / ARP ]====================="
ip neigh show || true
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Sockets (basic view)
# -----------------------------
{
echo "====================[ SOCKETS ]=============================="
ss -tulpen || true
echo ""
} >> "$OUT_FILE"

# -----------------------------
# iptables (if present)
# -----------------------------
{
echo "====================[ IPTABLES FILTER ]======================"
iptables -L -n -v 2>/dev/null || echo "iptables not available or no rules"
echo ""
echo "====================[ IPTABLES NAT ]========================="
iptables -t nat -L -n -v 2>/dev/null || echo "iptables NAT not available or no rules"
echo ""
} >> "$OUT_FILE"

# -----------------------------
# eBPF (if available)
# -----------------------------
{
echo "====================[ BPF PROGRAMS ]========================="
bpftool prog show 2>/dev/null || echo "bpftool not installed or no access"
echo ""
echo "====================[ BPF MAPS ]============================="
bpftool map show 2>/dev/null || echo "bpftool not installed or no access"
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Cilium logs (if exists)
# -----------------------------
{
echo "====================[ CILIUM CNI LOG ]======================="
if [[ -f /var/run/cilium/cilium-cni.log ]]; then
  cat /var/run/cilium/cilium-cni.log
else
  echo "No Cilium CNI log found"
fi
echo ""
} >> "$OUT_FILE"

# -----------------------------
# Summary hint
# -----------------------------
{
echo "====================[ SUMMARY NOTES ]========================"
echo "Look for changes in:"
echo " - cilium_host / cilium_vxlan interfaces"
echo " - veth pairs"
echo " - new routes (pod CIDRs)"
echo " - bpftool programs attached to tc/cgroup"
echo ""
echo "Compare snapshots using:"
echo "  diff file_before.log file_after.log"
echo "============================================================"
} >> "$OUT_FILE"

echo "[✓] Snapshot complete: $OUT_FILE"

# diff /tmp/network-snapshots/network-*-before.log /tmp/network-snapshots/network-*-after.log