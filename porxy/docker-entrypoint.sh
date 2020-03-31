#!/bin/bash

ip=$(ip -4 addr show docker0 2>/dev/null | grep -Po 'inet \K[\d.]+')
if [ -z "$ip" ];then
  ip=$(ping -c 1 host.docker.internal | head -n 1 | sed -r 's/PING\shost\.docker\.internal\s\(([^\)]+).*/\1/')
fi

echo -e "${ip}\tmaster-account.example.com.local">>/etc/hosts

exec "$@"
