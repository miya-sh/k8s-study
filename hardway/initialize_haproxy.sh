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
${BACKEND_MASTER}

backend kubernetes-worker-nodes
    mode tcp
    balance roundrobin
    option tcp-check
${BACKEND_WORKER}
EOF

systemctl restart haproxy
