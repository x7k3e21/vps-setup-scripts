
#!/usr/bin/env bash

set -e

iptables -D FORWARD -i %i -j ACCEPT
iptables -D FORWARD -o %i -j ACCEPT

iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

iptables -D INPUT -s 10.8.0.1/24 -p tcp -m tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -D INPUT -s 10.8.0.1/24 -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT