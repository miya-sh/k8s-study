#!/bin/bash

apt install -y haproxy
sysctl -w net.ipv4.ip_forward=1

cat <<EOF | tee /etc/haproxy/haproxy.cfg 
frontend kubernetes
    bind ${KUBERNETES_PUB_ADDR}:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server master-1 172.16.10.1:6443 check fall 3 rise 2
    server master-2 172.16.10.2:6443 check fall 3 rise 2
EOF

systemctl restart haproxy
