#!/usr/bin/env bash
set -euo pipefail
umask 077

# -----------------------------
# Configuration
# -----------------------------
TPM_DIR="/etc/step-ca/tpm"
PERSISTENT_HANDLE="0x81000000"
PCRS="sha256:0,1,2,3"

PRIMARY_CTX="$(mktemp /run/step-primary.XXXXXX.ctx)"
SEALED_CTX="$(mktemp /run/step-sealed.XXXXXX.ctx)"

KEY_PUB="${TPM_DIR}/key.pub"
KEY_PRIV="${TPM_DIR}/key.priv"
PCR_BIN="${TPM_DIR}/pcr.bin"
PCR_POLICY="${TPM_DIR}/pcr.policy"

# -----------------------------
# Cleanup safety
# -----------------------------
cleanup() {
  rm -f "$PRIMARY_CTX" "$SEALED_CTX" || true
  unset STEP_CA_PASSWORD || true
}
trap cleanup EXIT

# -----------------------------
# Prepare TPM directory
# -----------------------------
sudo mkdir -p "$TPM_DIR"
sudo chmod 700 "$TPM_DIR"
sudo chown root:root "$TPM_DIR"

# -----------------------------
# Check existing TPM object
# -----------------------------
EXISTS=0
if sudo tpm2_getcap handles-persistent | grep -q "$PERSISTENT_HANDLE"; then
  EXISTS=1
fi

if [[ "$EXISTS" -eq 1 ]]; then
  echo "[!] TPM object already exists at handle: $PERSISTENT_HANDLE"

  if [[ "${FORCE:-0}" != "1" ]]; then
    echo ""
    echo "Do you want to overwrite it? (this will delete existing root secret)"
    read -r -p "Type 'yes' to continue: " CONFIRM

    if [[ "$CONFIRM" != "yes" ]]; then
      echo "[*] Aborting. Existing TPM object preserved."
      exit 0
    fi
  else
    echo "[*] FORCE=1 detected, skipping prompt"
  fi

  echo "[*] Evicting existing TPM object..."
  sudo tpm2_evictcontrol -C o -c "$PERSISTENT_HANDLE" || true
fi

# -----------------------------
# Secure password input
# -----------------------------
echo "[*] Enter Step-CA bootstrap password (NOT stored on disk):"
read -r -s STEP_CA_PASSWORD
echo ""

if [[ -z "${STEP_CA_PASSWORD}" ]]; then
  echo "[ERROR] Empty password not allowed"
  exit 1
fi

# -----------------------------
# TPM primary key
# -----------------------------
echo "[*] Creating TPM primary context..."
sudo tpm2_createprimary -C o -c "$PRIMARY_CTX" >/dev/null

# -----------------------------
# PCR binding
# -----------------------------
echo "[*] Capturing PCR state ($PCRS)..."
sudo tpm2_pcrread -Q -o "$PCR_BIN" "$PCRS"

echo "[*] Creating PCR policy..."
sudo tpm2_createpolicy \
  -Q \
  --policy-pcr \
  -l "$PCRS" \
  -f "$PCR_BIN" \
  -L "$PCR_POLICY"

# -----------------------------
# Seal secret
# -----------------------------
echo "[*] Sealing Step-CA password into TPM..."

printf "%s" "$STEP_CA_PASSWORD" | sudo tpm2_create \
  -C "$PRIMARY_CTX" \
  -L "$PCR_POLICY" \
  -u "$KEY_PUB" \
  -r "$KEY_PRIV" \
  -i -

unset STEP_CA_PASSWORD

# -----------------------------
# Load + persist
# -----------------------------
echo "[*] Loading sealed TPM object..."
sudo tpm2_load \
  -C "$PRIMARY_CTX" \
  -u "$KEY_PUB" \
  -r "$KEY_PRIV" \
  -c "$SEALED_CTX"

echo "[*] Persisting TPM object..."
sudo tpm2_evictcontrol \
  -C o \
  -c "$SEALED_CTX" \
  "$PERSISTENT_HANDLE"

echo "[*] Cleaning transient TPM contexts..."
sudo rm -f "$PRIMARY_CTX"
sudo rm -f "$SEALED_CTX"

# -----------------------------
# Secure artifacts
# -----------------------------
sudo chmod 600 "$KEY_PUB" "$KEY_PRIV" "$PCR_BIN" "$PCR_POLICY"
sudo chown root:root "$KEY_PUB" "$KEY_PRIV" "$PCR_BIN" "$PCR_POLICY"

# -----------------------------
# Output
# -----------------------------
echo ""
echo "[+] TPM sealing complete"
echo "[+] Handle: $PERSISTENT_HANDLE"