#!/usr/bin/env bash
set -euo pipefail
umask 077

STEP_CA_NAME="step-ca"
CRED_NAME="ca-password"
CRED_DIR="/etc/credstore.encrypted/${STEP_CA_NAME}"
CRED_FILE="${CRED_DIR}/${CRED_NAME}"
SERVICE_FILE="/etc/systemd/system/${STEP_CA_NAME}.service"

sudo mkdir -p "$CRED_DIR"
sudo chmod 700 "$CRED_DIR"

echo "[*] Bootstrapping Step-CA systemd service..."
# -------------------------------------------------
# systemd service
# -------------------------------------------------
sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Step CA with TPM-backed credential
After=network.target

[Service]
Type=simple

ExecStartPre=/usr/local/bin/unseal-step-ca-secret.sh
ExecStart=/usr/bin/step-ca /etc/step-ca/config/ca.json

User=step

# Hardened isolation
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Step CA Service
After=network.target

[Service]
Type=simple

# systemd decrypts this into /run/credentials/step-ca.service/
LoadCredentialEncrypted=${CRED_NAME}:${CRED_FILE}

ExecStart=/usr/bin/step-ca /etc/step-ca/config/ca.json

User=step

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
RestrictSUIDSGID=true

[Install]
WantedBy=multi-user.target
EOF



sudo bash -c '
read -s -p "Enter Step-CA password: " PW; echo
printf "%s" "$PW" | tpm2_createprimary -C o -c primary.ctx
printf "%s" "$PW" | tpm2_create -C primary.ctx -u key.pub -r key.priv
tpm2_load -C primary.ctx -u key.pub -r key.priv -c ca_sealed.ctx
unset PW
'

# Unseal directly into memory pipe for step-ca init usage
tpm2_unseal -c /etc/step-ca/ca_sealed.ctx








# ----------------------------
# 3. Reload + enable
# ----------------------------
echo "[*] Reloading systemd..."
sudo systemctl daemon-reload

echo "[*] Enabling service..."
sudo systemctl enable "$UNIT"

echo "[*] Done. Start with: systemctl start $UNIT"