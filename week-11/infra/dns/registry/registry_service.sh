#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EVENTS_SERVICE="/etc/systemd/system/registry-events.service"
RECONCILER_SERVICE="/etc/systemd/system/registry-reconciler.service"

echo "[+] Installing registry system..."

# -----------------------------
# events service
# -----------------------------
sudo tee "$EVENTS_SERVICE" >/dev/null <<EOF
[Unit]
Description=Registry Events Listener
After=network.target containerd.service etcd.service
Requires=containerd.service etcd.service

[Service]
ExecStart=/usr/bin/bash ${DIR}/registry_events.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------
# reconciler service
# -----------------------------
sudo tee "$RECONCILER_SERVICE" >/dev/null <<EOF
[Unit]
Description=Registry Reconciler Service (30s drift correction)
After=network.target containerd.service etcd.service
Wants=containerd.service etcd.service

[Service]
ExecStart=/usr/bin/bash ${DIR}/registry_reconciler.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------
# reload + enable
# -----------------------------
sudo systemctl daemon-reload

sudo systemctl enable registry-events.service
sudo systemctl enable registry-reconciler.service

sudo systemctl restart registry-events.service
sudo systemctl restart registry-reconciler.service

echo "[✓] Registry system running:"
echo "   - registry-events.service"
echo "   - registry-reconciler.service"