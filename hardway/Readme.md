# Ref.
- https://github.com/kelseyhightower/kubernetes-the-hard-way
- https://github.com/mmumshad/kubernetes-the-hard-way


# Setup

- Go
  - install https://golang.org/doc/install

- cfssl
  - build & install https://github.com/cloudflare/cfssl

- vagrant plugin
  - vagrant-env: https://github.com/gosuri/vagrant-env

- kubectl
  - install https://kubernetes.io/ja/docs/tasks/tools/install-kubectl/

- generate keys and configs
  ```
  generate_necessaries.sh
  ```

- vm & k8s up
  ```
  vagrant up
  ```

- (opt) set kubeconfig environ
  ```
  export KUBECONFIG=path/to/client.kubeconfig
  ```

- CoreDNS
  ```
  kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml
  ```

- Network Addon
  https://kubernetes.io/ja/docs/concepts/cluster-administration/networking/
  - Weave
  https://www.weave.works/docs/net/latest/kubernetes/kube-addon/
  ```
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
  ```

- permit `kubectl exec`
  ```
  cat <<EOF | kubectl apply -f -
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: apiserver-kubelet-api-admin
  subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: system:kubelet-api-admin
  EOF
  ```

- Kubelet Authorization
  https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding
  ```
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRole
  metadata:
    name: system:kube-apiserver-to-kubelet
    annotations:
      rbac.authorization.kubernetes.io/autoupdate: "true"
    labels:
      kubernetes.io/bootstrapping: rbac-defaults
  rules:
  - apiGroups: [""]
    resources: ["*"]
    verbs: ["*"]
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: system:kube-apiserver
    namespace: ""
  subjects:
  - kind: User
    name: system:kube-apiserver
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: ClusterRole
    name: system:kube-apiserver-to-kubelet
    apiGroup: rbac.authorization.k8s.io
  ```

# Test

- sample1
  ```
  cat <<EOF | kubectl apply -f -
  apiVersion: v1
  kind: Service
  metadata:
    name: sample1-svc
  spec:
    selector:
      app: sample1
    type: NodePort
    ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: sample1-deploy
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: sample1
    template:
      metadata:
        labels:
          app: sample1
      spec:
        containers:
        - name: nginx
          image: nginx
          ports:
          - containerPort: 80
  EOF
  ```
  check endpoint `kubectl describe svc sample1-svc`
  access `http://${KUBERNETES_PUB_ADDR}:30080`
