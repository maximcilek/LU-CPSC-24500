#!/usr/bin/env bash
set -euo pipefail

sudo systemctl disable --now step-ca.service
sudo systemctl disable --now step-ca-bootstrap.service
sudo rm -f /etc/systemd/system/step-ca.service
sudo rm -f /etc/systemd/system/step-ca-bootstrap.service
sudo rm -f /etc/systemd/system/multi-user.target.wants/step-ca.service
sudo rm -f /etc/systemd/system/multi-user.target.wants/step-ca-bootstrap.service
sudo systemctl daemon-reload
sudo systemctl reset-failed

sudo rm -rf /usr/local/bin/step-ca-bootstrap.sh
sudo rm -rf /usr/local/bin/step-ca-runtime.sh

sudo nerdctl container stop step-ca
sudo nerdctl container rm step-ca