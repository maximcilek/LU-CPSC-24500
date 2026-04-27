#!/usr/bin/env bash
set -uo

# -----------------------------
# Load platform environment
# -----------------------------
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../config" && pwd)/platform.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] Missing env file: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

# -----------------------------
# REQUIRED ENV VALIDATION
# -----------------------------
: "${NETWORK_NAME:?Missing NETWORK_NAME}"
: "${ETCD_HOST:?Missing ETCD_HOST}"
: "${ETCD_CLIENT_PORT:?Missing ETCD_CLIENT_PORT}"
: "${ETCD_BASE:?Missing ETCD_BASE}"

echo "[+] Starting CoreDNS registry controller..."
echo "    ETCD=${ETCD_HOST}:${ETCD_CLIENT_PORT}"
echo "    BASE=${ETCD_BASE}"

# -----------------------------
# helper: write to etcd
# -----------------------------
etcd_put() {
  local key="$1"
  local value="$2"

  curl -sS -X POST "http://${ETCD_HOST}:${ETCD_CLIENT_PORT}/v3/kv/put" \
    -d "{\"key\":\"$(echo -n "$key" | base64)\",\"value\":\"$(echo -n "$value" | base64)\"}" \
    >/dev/null || true
}

# -----------------------------
# helper: delete from etcd
# -----------------------------
etcd_delete() {
  local key="$1"

  curl -sS -X POST "http://${ETCD_HOST}:${ETCD_CLIENT_PORT}/v3/kv/deleterange" \
    -d "{\"key\":\"$(echo -n "$key" | base64)\",\"range_end\":\"$(echo -n "$key" | base64)\"}" \
    >/dev/null || true
}

# -----------------------------
# initial reconciliation
# -----------------------------
echo "[+] Reconciling existing containers..."

for cid in $(nerdctl ps -q); do
  name=$(nerdctl inspect "$cid" 2>/dev/null | jq -r '.[0].Name' | sed 's|/||')
  ip=$(nerdctl inspect "$cid" 2>/dev/null | jq -r '.[0].NetworkSettings.IPAddress')

  if [[ -n "${name:-}" && -n "${ip:-}" && "$ip" != "null" ]]; then
    etcd_put "${ETCD_BASE}/${name}" "{\"ip\":\"${ip}\"}"
    echo "[REGISTERED] $name -> $ip"
  fi
done

# -----------------------------
# event-driven registry loop (PRODUCTION SAFE)
# -----------------------------
while true; do

  nerdctl events --format '{{json .}}' 2>/dev/null | \
  while IFS= read -r event; do

    [[ -z "${event:-}" ]] && continue

    type=$(echo "$event" | jq -r '.Type // empty')
    action=$(echo "$event" | jq -r '.Action // empty')
    id=$(echo "$event" | jq -r '.ID // empty')   # FIXED: ID not id

    [[ "$type" != "container" ]] && continue
    [[ -z "$id" ]] && continue

    # safer inspect (avoid crashing loop)
    inspect=$(nerdctl inspect "$id" 2>/dev/null || true)

    name=$(echo "$inspect" | jq -r '.[0].Name // empty' | sed 's|/||')
    ip=$(echo "$inspect" | jq -r '.[0].NetworkSettings.IPAddress // empty')

    [[ -z "$name" ]] && continue

    key="${ETCD_BASE}/${name}"

    case "$action" in
      start)
        [[ -z "$ip" || "$ip" == "null" ]] && continue
        etcd_put "$key" "{\"ip\":\"$ip\"}"
        echo "[START] $name -> $ip"
        ;;

      die|stop|destroy)
        etcd_delete "$key"
        echo "[REMOVE] $name"
        ;;
    esac

  done

  echo "[WARN] nerdctl events stream restarted - reconnecting..."
  sleep 1
done