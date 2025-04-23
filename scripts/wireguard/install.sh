
#!/usr/bin/env bash

apt-get install wireguard

WIREGUARD_CONFIG_DIR=/etc/wireguard

mkdir -p $WIREGUARD_CONFIG_DIR/keys

SERVER_PRIVATE_KEY="${WIREGUARD_CONFIG_DIR}/keys/private.key"
SERVER_PUBLIC_KEY="${WIREGUARD_CONFIG_DIR}/keys/public.key"

wg genkey | tee $SERVER_PRIVATE_KEY | wg pubkey > $SERVER_PUBLIC_KEY

cp ./server/wg0.conf $WIREGUARD_CONFIG_DIR/wg0.conf
cp -R ./scripts $WIREGUARD_CONFIG_DIR

chmod 600 -R $WIREGUARD_CONFIG_DIR

ip link add dev wg0 type wireguard

SYSCTL_CONFIG=/etc/sysctl.d/wg.conf

echo "net.ipv4.ip_forward = 1" > $SYSCTL_CONFIG
echo "net.ipv6.conf.all.forwarding = 1" >> $SYSCTL_CONFIG

sysctl --load $SYSCTL_CONFIG

systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service

apt-get install qrencode