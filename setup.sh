
#!/usr/bin/env bash

apt-get update --allow-releaseinfo-change
apt-get update

apt-get upgrade -y

apt-get install iptables -y

