#!/bin/zsh

etcdctl member list --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem

kubectl cluster-info --kubeconfig /var/lib/kubernetes/admin.kubeconfig

kubectl cluster-info --kubeconfig tmp/client.kubeconfig