# K3D

To test Airgap BigBang on k3d

## Steps

- Launch ec2 instance of size `c5.2xlarge` and ssh into the instance with at least 50GB storage.

- Install [Docker](https://docs.docker.com/engine/install/ubuntu/)

- Install [K3D](https://k3d.io/#installation)

- Download `images.tar.gz`, `repositories.tar.gz` and `bigbang-version.tar.gz` from BigBang release.

  ```bash
  $ curl -O https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/1.2.0/repositories.tar.gz
  $ curl -O https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/1.2.0/images.tar.gz
  $ curl -O https://repo1.dso.mil/platform-one/big-bang/bigbang/-/archive/1.2.0/bigbang-1.2.0.tar.gz
  ```

  

- Follow [Airgap Documentation](../README.md) to install Git server and Registry.

- Once Git Server and Registry is up, setup k3d mirroring configuration  `registries.yaml`

  ```yaml
  mirrors:
    registry.dso.mil:
      endpoint:
        - https://[$PRIVATEIP]:5443
    registry1.dso.mil:
      endpoint:
        - https://[$PRIVATEIP]:5443
    docker.io:
      endpoint:
        - https://[$PRIVATEIP]:5443
  configs:
    myregistry.com:5443:
      tls:
        ca_file: "/etc/ssl/certs/registry1.pem"
  ```

  

- Launch k3d cluster

  ```bash
  $ PRIVATEIP=$( curl http://169.254.169.254/latest/meta-data/local-ipv4 )
  $ k3d cluster create --api-port "${PRIVATEIP}:33989" -s 1 -a 2 -v "${HOME}/registries.yaml:/etc/rancher/k3s/registries.yaml" -v /etc/machine-id:/etc/machine-id -v "${HOME}/certs/myregistry.com.public.pem:/etc/ssl/certs/registry1.pem" --k3s-server-arg "--disable=traefik" --k3s-server-arg "--disable=metrics-server" --k3s-server-arg "--tls-san=$PRIVATEIP"  -p 80:80@loadbalancer -p 443:443@loadbalancer
  ```

  

- Bock all egress with `iptables` except those going to instance IP before deploying bigbang  by running [k3d_airgap.sh](./scripts/k3d_airgap.sh)

  ```bash
  
  ```

  

  ```bash
  $ sudo ./k3d_airgap.sh
  $ curl https://index.docker.io/ #shouldnt work
  $ curl https://$PRIVATEIP:5443/v2/_catalog -k #show return list of images
  curl https://$PRIVATEIP:5443/v2/repositories/rancher/library-busybox/tags
  ```

​		To permanently save the iptable rules across reboot, check out [link](https://unix.stackexchange.com/questions/52376/why-do-iptables-rules-disappear-when-restarting-my-debian-system)

- Test that  mirroring is working

```bash
$ kubectl run -i --tty  test --image=registry1.dso.mil/rancher/library-busybox:1.31.1 --image-pull-policy='Always' -- sh
$ kubectl run test --image=registry1.dso.mil/rancher/library-busybox:1.31.1 --image-pull-policy='Always' --restart=Never --command sleep infinity
$ telnet default.kube-system.svc.cluster.local 443
$ kubectl describe po test
$ kubectl delete po test
```

- Test that cluster cannot pull outside private registry.

```bash
$ kubectl run test --image=nginx
$ kubectl describe po test #should fail
$ kubectl delete po test
```



- 
- Proceed to [bigbang deployment process](../README.md#installing-big-bang) 