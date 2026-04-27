#!/usr/bin/env bash
set -euo pipefail

cleanup_nerdctl_cni() {

  echo "[+] Stopping containerd..."
  sudo systemctl stop containerd

  echo "[+] Removing nerdctl-managed networks..."
  sudo nerdctl network prune -f || true

  echo "[+] Deleting all containers (optional safety reset)..."
  sudo nerdctl ps -aq | xargs -r sudo nerdctl rm -f || true

  echo "[+] Removing CNI configuration..."
  sudo rm -rf /etc/cni/net.d/*

  echo "[+] Removing CNI runtime state..."
  sudo rm -rf /var/lib/cni

  echo "[+] Removing containerd network state..."
  sudo rm -rf /run/containerd/netns || true
  sudo rm -rf /run/netns/* || true

  echo "[+] Deleting leftover bridge / CNI interfaces..."

  # common defaults
  for iface in nerdctl0 cni0 cni-br0 br0 docker0; do
    sudo ip link delete "$iface" 2>/dev/null || true
  done

  echo "[+] Flushing stale network namespaces (safe reset)"
  sudo ip netns list 2>/dev/null | awk '{print $1}' | while read ns; do
    sudo ip netns delete "$ns" 2>/dev/null || true
  done

  echo "[+] Restarting containerd..."
  sudo systemctl start containerd

  echo "[✓] CLEAN RESET COMPLETE"
}

cleanup_nerdctl_cni