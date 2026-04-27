#!/usr/bin/env bash
set -uo pipefail

DNS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo bash "${DNS_DIR}/coredns/coredns.sh"
sudo bash "${DNS_DIR}/registry/registry_service.sh"

sudo systemctl daemon-reload