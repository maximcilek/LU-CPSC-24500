#!/usr/bin/env bash
set -uo pipefail

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../config" && pwd)/platform.env"

set -a
source "$ENV_FILE"
set +a

: "${ETCD_HOST:?Missing ETCD_HOST}"
: "${ETCD_CLIENT_PORT:?Missing ETCD_CLIENT_PORT}"
: "${ETCD_BASE:?Missing ETCD_BASE}"

echo "[+] registry-events.sh started"

etcd_put() {
  local key="$1"
  local value="$2"

  ETCDCTL_API=3 etcdctl put "$key" "$value"
}
etcd_delete() {
  local key="$1"

  ETCDCTL_API=3 etcdctl del "$key"
}
etcd_delete_prefix() {
  local prefix="$1"

  ETCDCTL_API=3 etcdctl del "$prefix" --prefix
}

while true; do
  nerdctl events --format '{{json .}}' 2>/dev/null | \
  while IFS= read -r event; do

    [[ -z "$event" ]] && continue

    type=$(echo "$event" | jq -r '.Type // empty')
    action=$(echo "$event" | jq -r '.Action // empty')
    id=$(echo "$event" | jq -r '.host // empty')

    [[ "$type" != "container" ]] && continue
    [[ -z "$id" ]] && continue

    name=$(nerdctl inspect "$id" 2>/dev/null | jq -r '.[0].Name' | sed 's|/||')
    ip=$(nerdctl inspect "$id" 2>/dev/null | jq -r '.[0].NetworkSettings.IPAddress')

    [[ -z "$name" ]] && continue

    key="${ETCD_BASE}/internal/svc/${name}"

    case "$action" in
      start)
        [[ -z "$ip" || "$ip" == "null" ]] && continue
        etcd_put "$key" "{\"host\":\"$ip\"}"
        echo "[EVENT START] $name -> $ip"
        ;;

      die|stop|destroy)
        etcd_delete "$key"
        echo "[EVENT REMOVE] $name"
        ;;
    esac

  done

  echo "[WARN] event stream restarted"
  sleep 1
done