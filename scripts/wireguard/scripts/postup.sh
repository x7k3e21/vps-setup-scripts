
#!/usr/bin/env bash

set -e

iptables -A FORWARD -i %i -j ACCEPT
iptables -A FORWARD -o %i -j ACCEPT

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

iptables -A INPUT -s 10.8.0.1/24 -p tcp -m tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -s 10.8.0.1/24 -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT