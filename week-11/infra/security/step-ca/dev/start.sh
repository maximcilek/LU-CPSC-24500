#!/usr/bin/env bash
set -euo pipefail

sudo cp infra/security/step-ca/dev/step-ca-runtime.sh /usr/local/bin/
sudo cp infra/security/step-ca/dev/step-ca-bootstrap.sh /usr/local/bin/

sudo chmod +x /usr/local/bin/step-ca-*.sh

sudo cp infra/security/step-ca/dev/step-ca.service /etc/systemd/system/
sudo cp infra/security/step-ca/dev/step-ca-bootstrap.service /etc/systemd/system/

sudo chmod 644 /etc/systemd/system/step-ca*.service

sudo systemctl enable step-ca-bootstrap.service
sudo systemctl enable step-ca.service

sudo systemctl start step-ca-bootstrap.service
sudo systemctl start step-ca.service

sudo systemctl status step-ca.service
sudo systemctl status step-ca-bootstrap.service