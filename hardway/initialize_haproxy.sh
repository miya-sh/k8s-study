#!/bin/bash

apt install -y haproxy
sysctl -w net.ipv4.ip_forward=1

cat <<EOF | tee /etc/haproxy/haproxy.cfg 
frontend kubernetes
    bind ${KUBERNETES_PUB_ADDR}:6443
    bind ${KUBERNETES_PUB_ADDR}:30000-32767
    option tcplog
    mode tcp

    acl to_master dst_port 6443
    acl to_nodeport dst_port 30000-32767

    use_backend kubernetes-master-nodes if to_master
    use_backend kubernetes-worker-nodes if to_nodeport


backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server master-1 172.16.10.1:6443 check fall 3 rise 2
    server master-2 172.16.10.2:6443 check fall 3 rise 2

backend kubernetes-worker-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server worker-1 172.16.20.1 check fall 3 rise 2
    server worker-2 172.16.20.2 check fall 3 rise 2
EOF

systemctl restart haproxy
