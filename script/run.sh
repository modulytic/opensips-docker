#! /bin/bash

HOST_IP=$(ip route get 8.8.8.8 | head -n +1 | tr -s " " | cut -d " " -f 7)
sed -i "s/%@HOST@%/${HOST_IP}/g" /etc/opensips/opensips.cfg

service apache2 start
service mariadb start

iptables -t nat -A OUTPUT -o lo -p tcp --dport 8080 -j REDIRECT --to-port 3306

/usr/sbin/opensips -FE