# Install the Flux CLI Tool

```shell
sudo curl -s https://fluxcd.io/install.sh | sudo bash
```

> Fedora Note: kubectl is a prereq for flux, and flux expects it in `/usr/local/bin/kubectl` symlink it or copy the binary to fix errors.

## Install flux.yaml to the Cluster

```shell
export REGISTRY1_USER='REPLACE_ME'
export REGISTRY1_TOKEN='REPLACE_ME'
```

> In production use robot credentials, single quotes are important due to the '$'  
`export REGISTRY1_USER='robot$bigbang-onboarding-imagepull'`

```shell
kubectl create ns flux-system
kubectl create secret docker-registry private-registry \
    --docker-server=registry1.dso.mil \
    --docker-username=$REGISTRY1_USER \
    --docker-password=$REGISTRY1_TOKEN \
    --namespace flux-system
kubectl apply -k https://repo1.dso.mil/big-bang/bigbang.git//base/flux?ref=master
```
**NOTE:** You can replace ```master``` in the ```kubectl apply -k``` command above with tag of the Big Bang release you need. For example:
```
kubectl apply -k https://repo1.dso.mil/big-bang/bigbang/bigbang.git//base/flux?ref=2.14.0
```

### Now You Can See New CRD Objects Types Inside the Cluster

```shell
kubectl get crds | grep flux
```

## Advanced Installation

Clone the Big Bang repo and use the awesome installation [scripts](https://repo1.dso.mil/big-bang/bigbang/-/tree/master/scripts) directory.

```shell
git clone https://repo1.dso.mil/big-bang/bigbang.git
./bigbang/scripts/install_flux.sh
```

> **NOTE:** install_flux.sh requires arguments to run properly, calling it will print out a friendly USAGE message with required arguments needed to complete installation.
