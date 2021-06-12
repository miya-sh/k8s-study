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
