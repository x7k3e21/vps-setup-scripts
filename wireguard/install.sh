
# File: wireguard/install.sh

#!/bin/sh

set -x

WIREGUARD_CONFIG_DIR=/etc/wireguard

runSystemUpdate() {
    apt-get update --allow-releaseinfo-change
    apt-get update
}

runSystemUpgrade() {
    apt-get upgrade -y
}

installDependencies() {
    apt-get install -y wireguard
    apt-get install -y qrencode
}

configureServer() {
    mkdir -p $WIREGUARD_CONFIG_DIR/keys

    SERVER_PRIVATE_KEY="${WIREGUARD_CONFIG_DIR}/keys/private.key"
    SERVER_PUBLIC_KEY="${WIREGUARD_CONFIG_DIR}/keys/public.key"

    wg genkey | tee $SERVER_PRIVATE_KEY | wg pubkey > $SERVER_PUBLIC_KEY

    cp ./server/wg0.conf $WIREGUARD_CONFIG_DIR/wg0.conf

    chmod 600 -R $WIREGUARD_CONFIG_DIR
}

configureSysctl() {
    SYSCTL_CONFIG=/etc/sysctl.d/wg.conf

    echo "net.ipv4.ip_forward = 1" > $SYSCTL_CONFIG
    echo "net.ipv6.conf.all.forwarding = 1" >> $SYSCTL_CONFIG

    sysctl --load $SYSCTL_CONFIG
}

createClient() {
    WIREGUARD_CLIENT_NAME=$1

    mkdir -p $WIREGUARD_CONFIG_DIR/clients/$WIREGUARD_CLIENT_NAME/keys

    CLIENT_PRIVATE_KEY="${WIREGUARD_CONFIG_DIR}/clients/${WIREGUARD_CLIENT_NAME}/keys/private.key"
    CLIENT_PUBLIC_KEY="${WIREGUARD_CONFIG_DIR}/clients/${WIREGUARD_CLIENT_NAME}/keys/public.key"

    wg genkey | tee $CLIENT_PRIVATE_KEY | wg pubkey > $CLIENT_PUBLIC_KEY

    SERVER_PUBLIC_KEY="${WIREGUARD_CONFIG_DIR}/keys/public.key"

    OLD_USED_ADDRESS=$(grep -o "10.8.0.[0-9]\+" $WIREGUARD_CONFIG_DIR/wg0.conf | sort -t . -k 4 -n | tail -n 1 | cut -d . -f 4)
    NEW_USED_ADDRESS=$(($OLD_USED_ADDRESS + 1))

    CLIENT_CONFIG_FILE="${WIREGUARD_CONFIG_DIR}/clients/${WIREGUARD_CLIENT_NAME}.conf"
    SERVER_CONFIG_FILE="${WIREGUARD_CONFIG_DIR}/wg0.conf"

    cat > $CLIENT_CONFIG_FILE <<EOF

[Interface]
PrivateKey = $(cat "$CLIENT_PRIVATE_KEY")
Address = 10.8.0.$NEW_USED_ADDRESS/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $(cat "$SERVER_PUBLIC_KEY")
AllowedIPs = 0.0.0.0/0 
Endpoint = $(curl -s4 ifconfig.me):51194
EOF

    cat >> $SERVER_CONFIG_FILE <<EOF

### $WIREGUARD_CLIENT_NAME

[Peer]
PublicKey = $(cat "$CLIENT_PUBLIC_KEY")
AllowedIPs = 10.8.0.$NEW_USED_ADDRESS/32
EOF
}

showClientQR() {
    WIREGUARD_CLIENT_NAME=$1

    qrencode -t UTF8 -r $WIREGUARD_CONFIG_DIR/clients/$WIREGUARD_CLIENT_NAME.conf
}

startServer() {
    wg-quick up wg0

    systemctl enable wg-quick@wg0.service
}

restartServer() {
    systemctl restart wg-quick@wg0.service
}

SCRIPT_ACTION=$1

case $SCRIPT_ACTION in
    install )
        INSTALL_FLAG=$2

        runSystemUpdate

        if [[ "$INSTALL_FLAG" != "--no-upgrade" ]]; then
            runSystemUpgrade
        fi

        installDependencies

        configureServer
        configureSysctl

        startServer
        ;;

    client )
        WIREGUARD_CLIENT_NAME=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)

        createClient $WIREGUARD_CLIENT_NAME
        showClientQR $WIREGUARD_CLIENT_NAME

        restartServer
        ;;
esac