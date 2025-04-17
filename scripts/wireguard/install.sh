
#!/bin/sh

apt-get install wireguard
apt-get install qrencode

SYSCTL_CONFIG=/etc/sysctl.d/wg.conf

echo "net.ipv4.ip_forward = 1" >> $SYSCTL_CONFIG
echo "net.ipv6.conf.all.forwarding = 1" >> $SYSCTL_CONFIG

sysctl --load $SYSCTL_CONFIG

WIREGUARD_CONFIG_DIR=/etc/wireguard

mkdir -p $WIREGUARD_CONFIG_DIR

SERVER_PRIVATE_KEY="${WIREGUARD_CONFIG_DIR}/keys/private.key"
SERVER_PUBLIC_KEY="${WIREGUARD_CONFIG_DIR}/keys/public.key"

touch $SERVER_PRIVATE_KEY
touch $SERVER_PUBLIC_KEY

wg genkey | tee $SERVER_PRIVATE_KEY | wg pubkey > $SERVER_PUBLIC_KEY
