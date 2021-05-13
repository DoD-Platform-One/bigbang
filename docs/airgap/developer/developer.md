# K3D

To test Airgap BigBang on k3d

## Steps

- Launch EC2 instance of size `c5.2xlarge` and ssh into the instance with at least 50GB storage.

- Install `k3d` and `docker` cli tools

- Download `images.tar.gz`, `repositories.tar.gz` and `bigbang-version.tar.gz` from BigBang release.

  ```shell
  curl -O https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/1.3.0/repositories.tar.gz
  curl -O https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/1.3.0/images.tar.gz
  sudo apt install -y net-tools
  ```

- Follow [Airgap Documentation](../README.md) to install Git server and Registry.

- Once Git Server and Registry is up, setup k3d mirroring configuration  `registries.yaml`

  ```yaml
  mirrors:
    registry.dso.mil:
      endpoint:
        - https://host.k3d.internal:5443
    registry1.dso.mil:
      endpoint:
        - https://host.k3d.internal:5443
    docker.io:
      endpoint:
        - https://host.k3d.internal:5443
  configs:
    host.k3d.internal:5443:
      tls:
        ca_file: "/etc/ssl/certs/registry1.pem"
  ```

- Launch k3d cluster

  ```shell
  PRIVATEIP=$( curl http://169.254.169.254/latest/meta-data/local-ipv4 )
  $ k3d cluster create --image "rancher/k3s:v1.20.5-rc1-k3s1" --api-port "33989" -s 1 -a 2 -v "${HOME}/registries.yaml:/etc/rancher/k3s/registries.yaml" -v /etc/machine-id:/etc/machine-id -v "${HOME}/certs/host.k3d.internal.public.pem:/etc/ssl/certs/registry1.pem" --k3s-server-arg "--disable=traefik" --k3s-server-arg "--disable=metrics-server" --k3s-server-arg "--tls-san=$PRIVATEIP"  -p 80:80@loadbalancer -p 443:443@loadbalancer
  ```

- Block all egress with `iptables` except those going to instance IP before deploying bigbang  by running [k3d_airgap.sh](./scripts/k3d_airgap.sh)

```shell
sudo ./k3d_airgap.sh
curl https://$PRIVATEIP:5443/v2/_catalog -k # Show return list of images
curl https://$PRIVATEIP:5443/v2/repositories/rancher/library-busybox/tags
```

​To permanently save the iptable rules across reboot, check out [link](https://unix.stackexchange.com/questions/52376/why-do-iptables-rules-disappear-when-restarting-my-debian-system)

- Test that  mirroring is working

```shell
curl -k -X GET https://$PRIVATEIP:5443/v2/rancher/local-path-provisioner/tags/list
kubectl run -i --tty  test --image=registry1.dso.mil/rancher/local-path-provisioner:v0.0.19 --image-pull-policy='Always' --command sleep infinity -- sh
kubectl run test --image=registry1.dso.mil/rancher/library-busybox:1.31.1 --image-pull-policy='Always' --restart=Never --command sleep infinity
telnet default.kube-system.svc.cluster.local 443
kubectl describe po test
kubectl delete po test
```

- Test that cluster cannot pull outside private registry.

```shell
kubectl run test --image=nginx
kubectl describe po test # Should fail
kubectl delete po test
```

- Proceed to [bigbang deployment process](../README.md#installing-big-bang)
