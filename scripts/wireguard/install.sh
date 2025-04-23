
#!/usr/bin/env bash

WIREGUARD_CONFIG_DIR=/etc/wireguard

installDependencies() {
    apt-get install wireguard -y
    apt-get install qrencode -y
}

configureServer() {
    mkdir -p $WIREGUARD_CONFIG_DIR/keys

    SERVER_PRIVATE_KEY="${WIREGUARD_CONFIG_DIR}/keys/private.key"
    SERVER_PUBLIC_KEY="${WIREGUARD_CONFIG_DIR}/keys/public.key"

    wg genkey | tee $SERVER_PRIVATE_KEY | wg pubkey > $SERVER_PUBLIC_KEY

    cp ./server/wg0.conf $WIREGUARD_CONFIG_DIR/wg0.conf

    cp -R ./scripts $WIREGUARD_CONFIG_DIR

    chmod +X $WIREGUARD_CONFIG_DIR/scripts/postup.sh
    chmod +X $WIREGUARD_CONFIG_DIR/scripts/postdown.sh

    chmod 600 -R $WIREGUARD_CONFIG_DIR
}

configureSysctl() {
    SYSCTL_CONFIG=/etc/sysctl.d/wg.conf

    echo "net.ipv4.ip_forward = 1" > $SYSCTL_CONFIG
    echo "net.ipv6.conf.all.forwarding = 1" >> $SYSCTL_CONFIG

    sysctl --load $SYSCTL_CONFIG
}

createClient() {
    WIREGUARD_CLIENT_NAME=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)

    mkdir -p $WIREGUARD_CONFIG_DIR/clients/$WIREGUARD_CLIENT_NAME/keys

    CLIENT_PRIVATE_KEY="${WIREGUARD_CONFIG_DIR}/clients/${WIREGUARD_CLIENT_NAME}/keys/private.key"
    CLIENT_PUBLIC_KEY="${WIREGUARD_CONFIG_DIR}/clients/${WIREGUARD_CLIENT_NAME}/keys/public.key"

    wg genkey | tee $CLIENT_PRIVATE_KEY | wg pubkey > $CLIENT_PUBLIC_KEY

    OLD_USED_ADDRESS=$(grep -o "10.8.0.[0-9]\+" $WIREGUARD_CONFIG_DIR/wg0.conf | sort -t . -k 4 -n | tail -n 1 | cut -d "." -f 4)
    NEW_USED_ADDRESS=$(($OLD_USED_ADDRESS + 1))

    WIREGUARD_CLIENT_ADDRESS="10.8.0.${NEW_USED_ADDRESS}/32"

    
}

startServer() {
    wg-quick up wg0

    systemctl enable wg-quick@wg0.service
    systemctl start wg-quick@wg0.service
}