#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# CONFIG
# -------------------------
STEP_CA_URL="https://step-ca.svc.internal:9000"
PROVISIONER="admin"
CERT_DIR="/var/lib/mysql/tls"
CLIENT_NAME="mysql-client"
SERVER_NAME="mysql"
ROOT_CERT_PATH="$CERT_DIR/ca.crt"

mkdir -p "$CERT_DIR"

echo "[+] Step CA URL: $STEP_CA_URL"

# -------------------------
# 1. Fetch and install root CA (trust bootstrap)
# -------------------------
echo "[+] Fetching root certificates from Step CA"
sudo nerdctl run --rm \
  --network prod-net \
  -v ${CERT_DIR}:/tls \
  alpine:3.23.4 sh -c '
    apk add --no-cache curl openssl ca-certificates &&
    STEP_CA_URL="${STEP_CA_URL}" &&
    mkdir -p /tls &&
    curl -ks "${STEP_CA_URL}/roots.pem" > /tls/ca.crt &&
    wget -qO /usr/local/bin/step https://dl.smallstep.com/cli/docs-cli-install/latest/step_linux_amd64 &&
    chmod +x /usr/local/bin/step &&
    step ca certificate "mysql" /tls/server.crt /tls/server.key \
      --provisioner admin \
      --root /tls/ca.crt \
      --ca-url "$STEP_CA_URL"
'

curl -ks "$STEP_CA_URL/roots.pem" > "$ROOT_CERT_PATH"

# Validate we actually got a cert (fail fast if not)
if ! grep -q "BEGIN CERTIFICATE" "$ROOT_CERT_PATH"; then
  echo "[-] Failed to fetch valid root CA"
  exit 1
fi

# Normalize fingerprint (for logging / audit only)
STEP_FINGERPRINT=$(
  openssl x509 -in "$ROOT_CERT_PATH" -noout -fingerprint -sha256 \
  | cut -d= -f2 \
  | tr -d ':' \
  | tr '[:upper:]' '[:lower:]'
)

echo "[+] Root fingerprint: $STEP_FINGERPRINT"

# Install into system trust store (for MySQL/Postgres/OpenSSL clients)
echo "[+] Installing root CA into system trust store"
sudo cp "$ROOT_CERT_PATH" /usr/local/share/ca-certificates/step-ca-root.crt
sudo update-ca-certificates >/dev/null

# -------------------------
# 2. Generate CLIENT certificate
# -------------------------
echo "[+] Generating MySQL client certificate"

step ca certificate \
  "$CLIENT_NAME" \
  "$CERT_DIR/client.crt" \
  "$CERT_DIR/client.key" \
  --ca-url "$STEP_CA_URL" \
  --root "$ROOT_CERT_PATH" \
  --provisioner "$PROVISIONER" \
  --not-after 8760h \
  --force

# -------------------------
# 3. Generate SERVER certificate
# -------------------------
echo "[+] Generating MySQL server certificate"

step ca certificate \
  "$SERVER_NAME" \
  "$CERT_DIR/server.crt" \
  "$CERT_DIR/server.key" \
  --ca-url "$STEP_CA_URL" \
  --root "$ROOT_CERT_PATH" \
  --provisioner "$PROVISIONER" \
  --not-after 8760h \
  --san "$SERVER_NAME" \
  --san "localhost" \
  --force

# -------------------------
# 4. Secure permissions
# -------------------------
chmod 600 "$CERT_DIR"/*.key
chmod 644 "$CERT_DIR"/*.crt

# -------------------------
# 5. Output summary
# -------------------------
echo ""
echo "[✓] MySQL TLS certificates ready"
echo "-----------------------------------"
echo "CA cert     : $ROOT_CERT_PATH"
echo "Client cert : $CERT_DIR/client.crt"
echo "Client key  : $CERT_DIR/client.key"
echo "Server cert : $CERT_DIR/server.crt"
echo "Server key  : $CERT_DIR/server.key"