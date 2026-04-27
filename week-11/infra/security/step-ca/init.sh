#!/usr/bin/env bash
set -euo pipefail

sudo tee /etc/systemd/system/step-ca-init.service > /dev/null <<'EOF'
[Unit]
Description=Step CA Init

[Service]
Type=oneshot
ExecStart=/home/mcilek/Github/maximcilek/LU-CPSC-24500/week-11/infra/security/step-ca/step_ca_service.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable step-ca-init.service
sudo systemctl start step-ca-init.service