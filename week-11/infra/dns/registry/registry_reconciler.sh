#!/usr/bin/env bash
set -uo pipefail

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../config" && pwd)/platform.env"

set -a
source "$ENV_FILE"
set +a

: "${ETCD_HOST:?Missing ETCD_HOST}"
: "${ETCD_CLIENT_PORT:?Missing ETCD_CLIENT_PORT}"
: "${ETCD_BASE:?Missing ETCD_BASE}"

echo "[+] registry-reconciler started (30s loop)"

etcd_put() {
  local key="$1"
  local value="$2"

  ETCDCTL_API=3 etcdctl put "$key" "$value"
}
etcd_delete() {
  local key="$1"

  ETCDCTL_API=3 etcdctl del "$key"
}

reconcile() {
  declare -A live

  echo "[+] Reconciling state..."

  # -----------------------------
  # STEP 1: build truth from runtime
  # -----------------------------
  # for cid in $(nerdctl ps -q); do
  nerdctl ps -q | while read -r cid; do
    name=$(nerdctl inspect "$cid" 2>/dev/null | jq -r '.[0].Name' | sed 's|/||')
    ip=$(nerdctl inspect "$cid" 2>/dev/null | jq -r '.[0].NetworkSettings.IPAddress')

    [[ -z "$name" || "$ip" == "null" || -z "$ip" ]] && continue

    key="${ETCD_BASE}/internal/svc/${name}"
    live["$key"]="$ip"

    etcd_put "$key" "{\"host\":\"$ip\"}"
    echo "[RECONCILE SET] $name -> $ip"
  done

  # -----------------------------
  # STEP 2: remove stale entries
  # -----------------------------
  # pull all etcd keys under base prefix
  # keys=$(curl -s "http://${ETCD_HOST}:${ETCD_CLIENT_PORT}/v3/kv/range" -d "{\"key\":\"$(echo -n "$ETCD_BASE/" | base64)\",\"range_end\":\"$(echo -n "${ETCD_BASE}/\xff" | base64)\"}")
  
  keys=$(ETCDCTL_API=3 etcdctl get "$ETCD_BASE/" --prefix --keys-only)

  echo "$keys" | jq -r '.kvs[]?.key' 2>/dev/null | while read -r k; do
    decoded=$(echo "$k" | base64 --decode)

    if [[ -z "${live[$decoded]+x}" ]]; then
      etcd_delete "$decoded"
      echo "[RECONCILE DELETE] $decoded"
    fi
  done
}

# -----------------------------
# MAIN LOOP (every 30s)
# -----------------------------
while true; do
  reconcile
  sleep 30
done