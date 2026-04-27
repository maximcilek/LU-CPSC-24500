#!/usr/bin/env bash
set -euo pipefail

configure_cni_network_bridge() {

  CNI_CONF_DIR="/etc/cni/net.d"
  NETWORK_NAME="prod-net"
  BRIDGE_NAME="br0"
  SUBNET="10.30.0.0/16"
  GATEWAY="10.30.0.1"

  echo "[+] Configuring bridge CNI network..."

  sudo mkdir -p "$CNI_CONF_DIR"

  sudo tee "$CNI_CONF_DIR/10-${NETWORK_NAME}.conflist" >/dev/null <<EOF
{
  "cniVersion": "1.0.0",
  "name": "${NETWORK_NAME}",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "${BRIDGE_NAME}",
      "isGateway": true,
      "isDefaultGateway": true,
      "ipMasq": true,
      "hairpinMode": true,
      "mtu": 1500,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [
            {
              "subnet": "${SUBNET}",
              "gateway": "${GATEWAY}"
            }
          ]
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    },
    {
      "type": "firewall"
    },
    {
      "type": "tuning"
    },
    {
      "type": "loopback"
    }
  ]
}
EOF

  echo "[+] Enabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null

  echo "[+] Ensuring NAT masquerade rule..."
  sudo iptables -t nat -C POSTROUTING -s ${SUBNET} ! -o ${BRIDGE_NAME} -j MASQUERADE 2>/dev/null || \
  sudo iptables -t nat -A POSTROUTING -s ${SUBNET} ! -o ${BRIDGE_NAME} -j MASQUERADE

  echo "[✓] Bridge CNI network configured"
}

# =========================================================
# MAIN ENTRYPOINT
# =========================================================

configure_cni_network_bridge






#sudo nerdctl run -it --net prod-net --rm alpine sh
#ip a
#ping 8.8.8.8

#EXPECT 
#eth*: 10.88.x.x
#gateway: 10.88.0.1


# configure_cni_network_ipvlan() {
# 
#   CNI_CONF_DIR="/etc/cni/net.d"
#   PARENT_IF="$(ip -o link show \
#   | awk -F': ' '{print $2}' \
#   | grep -E '^(eth|enp|ens|eno|enx)' \
#   | head -n 1)"
# 
#   echo "[+] Configuring ipvlan CNI network on interface: $PARENT_IF"
# 
#   sudo mkdir -p "$CNI_CONF_DIR"
# 
#   sudo tee "$CNI_CONF_DIR/10-container-net.conflist" >/dev/null <<EOF
# {
#   "cniVersion": "1.1.0",
#   "name": "container-net",
#   "plugins": [
#     {
#       "type": "ipvlan",
#       "master": "enx98fc84e0d4b8",
#       "mode": "l2",
#       "ipam": {
#         "type": "host-local",
#         "ranges": [
#           [
#             {
#               "subnet": "10.10.0.0/16",
#               "gateway": "10.10.0.1"
#             }
#           ]
#         ],
#         "routes": [
#           { "dst": "0.0.0.0/0" }
#         ]
#       }
#     },
#     { "type": "loopback" }
#   ]
# }
# EOF
# 
#   echo "[+] Enabling IP forwarding..."
#   sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
# 
#   echo "[✓] IPvlan CNI network configured"
# }