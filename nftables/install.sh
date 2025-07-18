
# File: nftables/install.sh

#!/bin/sh

set -x

runSystemUpdate() {
    apt-get update --allow-releaseinfo-change
    apt-get update
}

runSystemUpgrade() {
    apt-get upgrade -y
}

installDependencies() {
    apt-get install -y nftables
}

configureNftables() {
    SYSTEMD_UNITS_DIR=/etc/systemd/system

    cp ./nftables/nftables.conf /etc/nftables.conf

    cp ./nftables/system/nft.service $SYSTEMD_UNITS_DIR/nft.service

    systemctl daemon-reload
    systemctl enable nft.service
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

        configureNftables
        ;;
esac