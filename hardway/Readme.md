# Ref.
- https://github.com/kelseyhightower/kubernetes-the-hard-way
- https://github.com/mmumshad/kubernetes-the-hard-way


# Env

- Go
  - gvm (https://github.com/moovweb/gvm)
  - use Go 1.16
    ```
    gvm install go1.16 -B
    gvm use go1.16
    ```

- kubectl
  https://kubernetes.io/ja/docs/tasks/tools/install-kubectl/

- cfssl
  build & install. see. https://github.com/cloudflare/cfssl

- vagrant plugin
  - vagrant-env (https://github.com/gosuri/vagrant-env)

- generate keys and configs
  ```
  generate_necessaries.sh
  ```

- vm & k8s up
  ```
  vagrant up
  ```

# k8s

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
