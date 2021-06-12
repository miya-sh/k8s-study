#!/bin/zsh
# needs `cfssl`, cfssljson, kubectl

source .env


DST_ROOT=${PWD}/artifacts
mkdir -p tmp; cd tmp

#
# Certificate Authority
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "Personal",
      "OU": "CA",
      "ST": "Kanagawa"
    }
  ]
}
EOF
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

#
# Admin Client Certificate
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "system:masters",
      "OU": "Kubernetes",
      "ST": "Kanagawa"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

#
# Kubelet Client (* follow work node config)
NODE_IPS=
for i in $(seq 1 2); do
HOSTNAME=worker-${i}
NODE_IP=${WORKER_IP_PREFIX}.${i}
cat > ${HOSTNAME}-csr.json <<EOF
{
  "CN": "system:node:${HOSTNAME}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "system:nodes",
      "OU": "Kubernetes",
      "ST": "Kanagawa"
    }
  ]
}
EOF
if [[ -n ${NODE_IPS} ]]; then
  NODE_IPS=${NODE_IPS},${NODE_IP}
else
  NODE_IPS=${NODE_IP}
fi
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
  -hostname=${HOSTNAME},${NODE_IP},${KUBERNETES_PUB_ADDR} \
  -profile=kubernetes ${HOSTNAME}-csr.json | cfssljson -bare ${HOSTNAME}
done

#
# Controller Manager Client
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes",
      "ST": "Kanagawa"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

#
# Kube Proxy Client Certificate
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "system:node-proxier",
      "OU": "Kubernetes",
      "ST": "Kanagawa"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

#
# Scheduler Client Certificate
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes",
      "ST": "Kanagawa"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler

#
# Kubernetes API Server Certificate (* follow master node config)
NODE_IPS=
for i in $(seq 1 2); do
  NODE_IP=${MASTER_IP_PREFIX}.${i}
  if [[ -n ${NODE_IPS} ]]; then
    NODE_IPS=${NODE_IPS},${NODE_IP}
  else
    NODE_IPS=${NODE_IP}
  fi
done
CLUSTER_IP=10.32.0.1
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local
HOSTNAME=${CLUSTER_IP},${NODE_IPS},${KUBERNETES_PUB_ADDR},127.0.0.1,${KUBERNETES_HOSTNAMES}
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "Kubernetes",
      "OU": "Kubernetes",
      "ST": "Kanagawa"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${HOSTNAME} -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

#
# Service Account Key Pair
cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Kawasaki",
      "O": "Kubernetes",
      "OU": "Kubernetes",
      "ST": "Kanagawa"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes service-account-csr.json | cfssljson -bare service-account

#
# distribute
# -- master
for i in $(seq 1 2); do
  HOSTNAME=master-${i}
  mkdir -p ${DST_ROOT}/${HOSTNAME}
  cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem ${DST_ROOT}/${HOSTNAME}
done
# -- worker
for i in $(seq 1 2); do
  HOSTNAME=worker-${i}
  mkdir -p ${DST_ROOT}/${HOSTNAME}
  cp ca.pem ${HOSTNAME}-key.pem ${HOSTNAME}.pem ${DST_ROOT}/${HOSTNAME}
done

#
# --- kubeconfig ---
#

CLUSTER_NAME=k8s-hardway
for i in $(seq 1 2); do
  HOSTNAME=worker-${i}
  kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUB_ADDR}:6443 \
    --kubeconfig=${HOSTNAME}.kubeconfig
  kubectl config set-credentials system:node:${HOSTNAME} \
    --client-certificate=${HOSTNAME}.pem \
    --client-key=${HOSTNAME}-key.pem \
    --embed-certs=true \
    --kubeconfig=${HOSTNAME}.kubeconfig
  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=system:node:${HOSTNAME} \
    --kubeconfig=${HOSTNAME}.kubeconfig
  kubectl config use-context default --kubeconfig=${HOSTNAME}.kubeconfig
done

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUB_ADDR}:6443 \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig
kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=admin \
  --kubeconfig=admin.kubeconfig
kubectl config use-context default --kubeconfig=admin.kubeconfig


kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUB_ADDR}:6443 \
  --kubeconfig=client.kubeconfig
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=client.kubeconfig
kubectl config set-context ${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=admin \
  --kubeconfig=client.kubeconfig
kubectl config use-context ${CLUSTER_NAME} --kubeconfig=client.kubeconfig

#
# distribute
# -- master
for i in $(seq 1 2); do
  HOSTNAME=master-${i}
  cp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${DST_ROOT}/${HOSTNAME}
done
# -- worker
for i in $(seq 1 2); do
  HOSTNAME=worker-${i}
  cp ${HOSTNAME}.kubeconfig kube-proxy.kubeconfig ${DST_ROOT}/${HOSTNAME}
done
cp client.kubeconfig ${DST_ROOT}

#
# --- Data Encryption ---
#
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

#
# distribute
for i in $(seq 1 2); do
  HOSTNAME=master-${i}
  cp encryption-config.yaml ${DST_ROOT}/${HOSTNAME}
done
for i in $(seq 1 2); do
  HOSTNAME=worker-${i}
  cp encryption-config.yaml ${DST_ROOT}/${HOSTNAME}
done
