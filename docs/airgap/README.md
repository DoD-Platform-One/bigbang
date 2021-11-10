# Airgap

Currently this is in proof of concept mode, so play around with this to get an idea of it.

This work was quickly developed to entertain certain paths for image packaging and deployment.

## Image Packaging / Deployment

`package_images.sh` - Proof of concept script for image packaging

* Dependencies
  * `docker` - The docker CLI tool
  * `images.txt` - A list of all requires airgap images
  * `jq` - The jq CLI tool
* Deliverables
  * `registry:package.tar.gz` - Modified `registry:2` container loaded with airgap images
    * NOTE - `registry:2` vs `harbor` vs anything else is trivial, we can use whatever we want
    * Packaged images are loaded and retrievable immediately upon container start
    * `/var/lib/registry-package` is created and populated with images
    * `/etc/docker/registry/config.yml` is templated to use new registry folder
    * This is due to the fact that `/var/lib/registry` is a docker volume

`deploy_images.sh` - Proof of concept script for image deployment

* Dependencies
  * `docker` - The docker CLI tool
  * `registry:package.tar.gz` - Modified `registry:2` container loaded with airgap images
* Deliverables
  * Running `registry` container with airgap images deployed and retrievable

Hack commands:

* `curl -sX GET http://localhost:5000/v2/_catalog | jq -r .`
  * Verify the catalog of a local running registry container

## Repository Packaging / Deployment

Airgap Deployment is a form of deployment which does not have any direct connection to the Internet or external network during cluster setup or runtime. During installation, bigbang requires certain images and git repositories for installation. Since we will be installing in internet-disconnected environment, we need to perform extra steps to make sure these resources are available.

## Requirements and Prerequisites

### General Prerequisites

* A kubernetes cluster with container mirroring support. There is a section below that covers mirroring in more detail with examples for supported clusters.
* BigBang(BB) [release artifacts](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases).
* Utility Server.

### Package Specific Prerequisites

#### Elastic (Logging)

Elastic requires a larger number of memory map areas than some OSes support by default. This can be change at startup with a cloud config or later using sysctl.

```shell
MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
    
    --==MYBOUNDARY==
    Content-Type: text/x-shellscript; charset="us-ascii"

    #!/bin/bash
    # Set the vm.max_map_count to 262144. 
    # Required for Elastic to run correctly without OOM errors.
    sysctl -w vm.max_map_count=262144
```

## Utility Server

Utility Server is an internet-disconnected server that will host the private registry and git server that are required to deploy bigbang. It should include these command-line tools below;

* `docker`: for running docker registry.
  * `registry:2` image
  * `openssl` for self-signed certificate.
* `curl`: For troubleshooting registry.
* `git`: for setup git server.

## Git Server

As part of  BB release, we provide `repositories.tar.gz` which contains all the git repositories that BB depend on for deployment. You have two options for serving up these packages for Flux.

### Option One

You can follow the process below to setup git with `repositories.tar.gz` on the Utility Server.

* Create Git user and SSH key

```shell
sudo useradd --create-home --shell /bin/bash git
ssh-keygen  -b 4096 -t rsa -f ~/.ssh/identity -q -N ""
```

* Create .SSH folder for `git` user

  ```shell
  sudo su - git
  mkdir -p .ssh && chmod 700 .ssh/
  touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
  exit
  ```
  
* Add client ssh key to `git` user `authorized_keys`

  ```shell
  sudo su
  cat /[client-public-key-path]/identity.pub >> /home/git/.ssh/authorized_keys
  exit
  ```

* Extract `repositories.tar.gz` to git user home directory

  ```shell
  sudo tar -xvf repositories.tar.gz --directory /home/git/
  ```

* Add Hostname alias

  ```shell
  PRIVATEIP=$( curl http://169.254.169.254/latest/meta-data/local-ipv4 )
  sudo sed -i -e '1i'$PRIVATEIP'   'myhostname.com'\' /etc/hosts
  sudo sed -i -e '1i'$PRIVATEIP'   'host.k3d.internal'\' /etc/hosts #only for k3d
  ```
  
* To test the client key;

  ```shell
  GIT_SSH_COMMAND='ssh -i /[client-private-key-path] -o IdentitiesOnly=yes' git clone git@[hostname/IP]:/home/git/repos/[sample-repo]
  
  #For example;
  GIT_SSH_COMMAND='ssh -i ~/.ssh/identity -o IdentitiesOnly=yes' git clone git@host.k3d.internal:/home/git/repos/bigbang 
  #checkout release branch
  git checkout 1.3.0
  ```
  
### Option Two

There are some cases where you do not have access to or cannot create an ssh user on the utility server. It is possible to run an ssh git server on a non-standard port using Docker.

* Create an SSH key

```shell
ssh-keygen  -b 4096 -t rsa -f ./identity -q -N ""
```

* Extract `repositories.tar.gz` to your working directory

```shell
sudo tar -xvf repositories.tar.gz
```

* Start the provided Docker image (TODO: move this to an IB image when ready)

```shell
docker run -d -p 4001:22 -v ${PWD}/identity.pub:/home/git/.ssh/authorized_keys -v ${PWD}/repos:/home/git servicesengineering/gitshim:0.0.1
```

You will now be able to test by checking out some of the code.

```shell
GIT_SSH_COMMAND='ssh -i /[client-private-key-path] -o IdentitiesOnly=yes' git clone git@[hostname/IP]:[PORT]/home/git/repos/[sample-repo]

# For example;
GIT_SSH_COMMAND='ssh -i ~/.ssh/identity -o IdentitiesOnly=yes' git clone git@host.k3d.internal:[PORT]/home/git/repos/bigbang 
# Check out release branch
git checkout 1.3.0
```

## Private Registry

Images needed to run BB in your cluster is packaged as part of the release in `images.tar.gz`. You can see the list of required images in `images.txt`. In our airgap environment, we need to setup a registry that our cluster can pull required images from or an existing cluster where we can copy images from `images.tar.gz` into.

### Set Up

To setup the registry, we will be using `registry:2` to run a  private registry with  self-signed certificate.

* First, untar `images.tar.gz`;

```shell
tar -xvf images.tar.gz -C .
```

* SCP `registry:2` tar file

```shell
docker save -o registry2.tar registry:2
docker save -o k3s.tar rancher/k3s:v1.20.5-rc1-k3s1 #check release matching version
scp registry2.tar k3s.tar ubuntu@hostname:~ #modify according to your environment
docker load -i registry2.tar #on your registry server
docker load -i k3s.tar
```

* Use the script [registry.sh](./scripts/registry.sh) to create registry;

```shell
$ chmod +x registry.sh && sudo ./registry.sh

Required information:
Enter bit size for certs (Ex. 4096): 4096
Enter number of days to sign the certs with (Ex. 3650): 3650
Enter the 'Country' for the cert (Ex. US): US
Enter the 'State' for the cert (Ex. CO): CO
Enter the 'Location' for the cert (Ex. ColoradoSprings): ColoradoSprings
Enter the 'Organization' for the cert (Ex. PlatformOne): PlatformOne
Enter the 'Organizational Unit' for the cert (Ex. Bigbang): BigBang
Enter the 'Common Name' for the cert (Must be a FQDN (at least one period character) E.g. myregistry.com): myregistry.com
Enter the 'Subject Alternative Name' for the cert(E.g. 1.2.3.4): 10.0.52.144

Generating certs ...
mkdir: cannot create directory ‘certs’: File exists
Generating RSA private key, 4096 bit long modulus
.............................................................................................................++
.....................................++
e is 65537 (0x10001)
Generating RSA private key, 4096 bit long modulus
......................................................................................................................++
.......................++
e is 65537 (0x10001)
Signature ok
subject=/C=US/ST=CO/L=ColoradoSprings/O=PlatformOne/CN=myregistry.com
Getting CA Private Key

Launching our private registry ...
def21e7025c7d4ea7bbb30603955e0b7da14d077592851b327e59d78a849cb7d

Installation finished ...

Notes
=====

To see images in the registry;

=========================
curl https://myhostname.com:5443/v2/_catalog -k
=========================
```

A folder is created with TLS certs that we are going to supply to our k8s cluster when pulling from the registry.

You can ensure the images are now loaded in the registry;

```shell
 curl -k https://myhostname.com:5443/v2/_catalog 
{"repositories":["ironbank/anchore/engine/engine","ironbank/anchore/enterprise/enterprise","ironbank/anchore/enterpriseui/enterpriseui","ironbank/big-bang/argocd","ironbank/bitnami/analytics/redis-exporter","ironbank/elastic/eck-operator/eck-operator","ironbank/elastic/elasticsearch/elasticsearch","ironbank/elastic/kibana/kibana","ironbank/fluxcd/helm-controller","ironbank/fluxcd/kustomize-controller","ironbank/fluxcd/notification-controller","ironbank/fluxcd/source-controller","ironbank/gitlab/gitlab/alpine-certificates","ironbank/gitlab/gitlab/cfssl-self-sign","ironbank/gitlab/gitlab/gitaly",...]
```

### Mirroring

The images specified as part of the helm charts in BB are expected to be sourced from `registry1.dso.mil` hence this registry needs to be mirrored to the one setup above. To reduce the amount of work needed on the developer part, we will be taking advantage of container mirroring which is supported by `containerd` as well as `cri-o`. Check if your container runtime supports this as it is required for smooth developer experience when deploying BB.  You should also check documentation on how your cluster supports passing these configuration to the runtime. For example, TKG and RKE2 support such configuration for `containerd` below to enable `registry.dso.mil` and `registry1.dso.mil` .

​You need to also configure your cluster with appropriate registry TLS. Please consult your cluster documentation on how to configure this.

If you need to handle mirroring manually, there is an example Ansible script provided that will update the containerd mirroring and restart the container runtimes for each node in your inventory. (copy-containerd-config.yaml)

#### Konvoy Cluster

Modify the `cluster.yaml` file and apply. More details can be found on the [D2iQ Konvoy documentation](https://docs.d2iq.com/dkp/konvoy/1.6/install/install-airgapped/).

```yaml
kind: ClusterConfiguration
apiVersion: konvoy.mesosphere.io/v1beta2
spec:
  imageRegistries:
    - server: https://registry1.dso.mil:443
      username: "myuser"
      password: "mypassword"
      default: true
    - server: https://registry.dso.mil:443
      username: "myuser"
      password: "mypassword"
      default: true
```

#### TKG Cluster

```yaml
...
      - path: /etc/containerd/config.toml
        content: |
          version = 2
          [plugins]
            [plugins."io.containerd.grpc.v1.cri"]
              sandbox_image = "registry.tkg.vmware.run/pause:3.2"
              [plugins."io.containerd.grpc.v1.cri".registry]
                [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
                  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry1.dso.mil"]
                    endpoint = ["https://myregistry.com:5443"]
                  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.dso.mil"]
                    endpoint = ["https://myregistry.com:5443"]
 ...
```

#### RKE2 cluster

```yaml
#registries.yaml
mirrors:
  registry.dso.mil:
    endpoint:
      - https://myhostname.com:5443
  registry1.dso.mil:
    endpoint:
      - https://myhostname.com:5443
  registry1.dso.mil:
    endpoint:
      - https://myhostname.com:5443
configs:
  myhostname.com:5443:
    tls:
      ca_file: "/etc/ssl/certs/registry1.pem"
```

## Installing Big Bang

```shell
cd bigbang
```

Install flux

Install Flux 2 into the cluster using the provided artifacts. These are located in the scripts section of the Big Bang repository.

```shell
kubectl apply -f ./scripts/deploy/flux.yaml
```

After Flux is up and running you are ready to deploy Big Bang. We will do this using Helm. To first check to see if Flux is ready you can do.

You can watch to see if Flux is reconciling the projects by watching the progress.

```shell
watch kubectl get all -n flux-system
```

We need a namespace for our preparations and eventually for Big Bang to deploy into.

```shell
kubectl create ns bigbang
```

Installing Big Bang in an air gap environment currently uses the Helm charts from the **[Big Bang Repo](https://repo1.dso.mil/platform-one/big-bang/bigbang)**.

All changes are modified in the custom [values.yaml](./scripts/values.yaml) file. Modify as needed and replace IP.

Change the hostname for the installation. It is currently set to the development domain:

```yaml
# -- Domain used for BigBang created exposed services, can be overridden by individual packages.
hostname: bigbang.dev
```

Add your registry URL. This will be the IP address or URL of the utility server or the registry in which you have loaded all of the Big Bang images (note: it is possible that your registry doesn't have a username or password, there will be ignored for insecure registries.):

```yaml
# -- Single set of registry credentials used to pull all images deployed by BigBang.
registryCredentials:
  registry: 10.0.52.144
  username: "asdfasdfasdf"
  password: "asdfasdfasdfasdfasdf"
  email: ""
```

For your Git repository you have two options for setting up the credentials.

Option 1: Use an existing secret.

```shell
cd ~/.ssh
ssh-keygen  -b 4096 -t rsa -f ~/.ssh/identity -q -N ""
ssh-keyscan  <YOUR GIT URL HERE> ./known_hosts

kubectl create secret generic -n bigbang ssh-credentials \
    --from-file=./identity \
    --from-file=./identity.pub \
    --from-file=./known_hosts
```

In the above example we created a new set of keys to use, you could also use an existing set of keys. These are just SSH keys, so any SSH key pair should work. The second command is going to create a known hosts file. There is no way to answer yes to the unknown hosts prompt, this alleviates that need.

Once we have our private key, public key and the known hosts file, we place all of those into the secret using kubectl. This creates a BASE64 encoded secret of these values. !!! It is VERY important that the names of the files match above. So if you are using your own keypair change the names. Kubernetes uses the names of the files to create the keys inside of the secret.

If you want to create your secret and store in the Kubernetes format you can add the -o yaml --dry-run to the above command to get that output.

```shell
kubectl create secret generic ssh-credentials \
    --from-file=./identity \
    --from-file=./identity.pub \
    --from-file=./known_hosts \
    -o yaml --dry-run
```

Once your secret is created you can add that value to the values.yaml that we were modifying above.

```yaml
git:
  # -- Existing secret to use for git credentials, must be in the appropriate format: https://toolkit.fluxcd.io/components/source/gitrepositories/#https-authentication
  existingSecret: "ssh-credentials"
```

** Note that we substituted the name of the secret from the example to the secret created above. This value is arbitrary, so if you created your secret with a different name use that name instead.

Option 2: Put the values of your ssh keys directly in the values.yaml file.

You can also elect to just put the key values and the known hosts directly into the chart's values.yaml file.

```shell
ssh-keygen -q -N "" -f ./identity
ssh-keyscan <YOUR GIT URL HERE> ./known_hosts

cat identity
cat identity.pub
cat known_hosts
```

Take the values from each of these files and place in the correct fields in the values.yaml.

```yaml
git:
    # -- SSH git credentials, privateKey, publicKey, and knownHosts must be provided
    privateKey: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEAwcG6YKsqDC6728XZ7/8oiqnQaw3OkQnvMBrzvZjxd//PsEog
      xVc+F9YqW4FIeTH57wN6JXIC4iMbE0QGd6+1yOoYiXkhi66tuO5FN+n4PeMnvKcC
      JXtFWme4W/9YnEk/3sbNOgAMPlhMhTsudzLiXtHd3g+xCmNs1pdEIInaNadrolWn
      QTM0krUCcC6VLCri7ae/pDloglX4cBJ+EfqFC94T6wUICPd1P7zYsy8WwIQtPhLT
      lbY8CHj9iMlxlUdwdiXTlifqHsPgTh3X5e9Vptd+wi0+vfjvrXd/8SuM1q8xdQvY
      bZ27AlhgfQsVl9WQrk/47xd3g430G4cqSbyhLQIDAQABAoIBAFlSu153akIFhXtz
      Ad7fbcxHLxs7WUCKKOevdTCyApgEqbWm5uazKqAIjqxytHuS65shqjz7C5M/Beti
      z+x7Z73BFiDCZBgmLNZ1mhmF1niJcTdKcvXel4FvEZHv7OTX7AcC9XfIr9xKDrTZ
      LLmtDqkR7UvDRiX44iMnxzOM+bkDsHVva00e3IoSiOsQ4DKQ1l/HFseVlPIaGzfZ
      Z2q0myUrBzlOYE06VJluhexsrrVDi7KdIfR8UGpN4kC5R/vOnOi7ycd4tfsZe2Wb
      CjbKMTNYRFnVTt6/SXAhhFu+kz0FftDXNTIOhikVB8ryZ5iyNXszYqiptUI9VUZB
      mQLdPuECgYEA9odVxlPUgSMLhbE5vD57jbtB6Cswy5ztAuyCHMABM4U6pVvFDSNb
      244y0ov0TzviaCZkb+0qrAM0ZSNItLQ1PmbeD0SnB4q/C8hDvVtpB+0SPBJMX8so
      49n1Wr5dH0axGMLaZXGmQ4DPEW/t0dNbYpN1Sxgn6KZPprISXigBufkCgYEAyTNe
      kY3vaJ6Nla1pBVUmiK7hu1G3Ddihy1w56upHbOnDvJySuVOM5HRPm2ISFwW38/b5
      5+cGKWnmu7UhFi1d8Iz3Kmr6kpfRxEDtbrk5rkgKJmTtduxAzBH8CTZfxuYIC5xS
      3fbcFpFYfrtE+3tjqlXJSOpLOuDqbA3uGwWFTdUCgYEAkSi9A8uGnAdDmJPzF/l+
      jMTPGOKdl7auBAO41S7lRi3Ti1xO2d6RDuVa3YiU8TakqIi6qQDwGFrGtiqhe+2E
      UFsHs9vLsfArb8eaw1uYq5c7HpHzsJASYp+LDcR7VpgsXRUWvZa+vI6S3oSWdu9J
      pvCGpxHxJdcPnWrKz/AknBkCgYAnej/U+W9/LJUFSFgx5qo/6Wh7M6ZiPh5I45it
      ojhPg3KXgHU9jco4TSYNi+mWwNV+NfiE6wyHdbMDI6ARVOd4uoAIv6M9NDLBeifc
      MNXDf3kWXXlGe0afg+va9uNGCH6NoKeVy8kVWIFvpFj9qxE8K8bp2qbWL6lveDA+
      9w9X3QKBgGtkQi9OI7TyrloZ5F6/0/LnOJMGd/+e2cJUN6Pa10ZAjQh12JZ5fK7i
      Vwh5l0P5CGQsuC96n4xPELoBnbTdr+y17f0o+kAuSDAsXnDf/Jjr0y/+uzL6YYCg
      VD1yNitgcQw6oHKdTbGn4jni3/VemzONOz0uTB+/K7WhW2J7faaJ
      -----END RSA PRIVATE KEY-----
    publicKey: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBwbpgqyoMLrvbxdnv/yiKqdBrDc6RCe8wGvO9mPF3/+wSiDFVz4X1ipbgUh3MfnvA2olcgLiIxsTRAZ8r7XI6hiJeSGLrq2123kU36fg94ye8pwIle0VaZ7hb/1icST/exs06AAw+WEyFOy53MuJe0d3e$"
    knownHosts: "10.0.52.144 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPFZzQ6BmaswdhT8UWD5a/VYmZYrGv1qD3T+euf/gFjkPkeySYRIyM+Kg/UdHCHVBzc4aaFdBDmugHimZ4lbWpE="
```

** Note the above values are all examples and are intentionally not operational keys.

Then install Big Bang using Helm.

```shell
    helm upgrade -i bigbang chart -n bigbang --create-namespace -f values.yaml
    watch kubectl get gitrepositories,kustomizations,hr,po -A
```

** Note that the --create-namespace isn't needed if you created it earlier, but it doesn't hurt anything.

You should see the different projects configure working through their reconciliation starting with "gatekeeper".

## Using 3rd Party Packages

The third party guide assumes that you already have or are planning to install Big Bang Core.

### Package your Git repository

Packaging your repository from Git

```shell
git clone --no-checkout https://repo1.dso.mil/platform-one/big-bang/apps/third-party/kafka.git && tar -zcvf kafka-repo.tar.gz kafka
```

This creates a tar of a full git repo without a checkout. After you have placed this git repo in its destination you can get the files to view by doing.

```shell
git checkout
```

### Package your registry images

Package image

```shell
docker save -o image-name.tar image-name:image-version
```

Unpack the image on your utility server

```shell
tar -xvf image-name.tar
```

Move the image to the location of your other images.

Restart your local registry and it should pick up the new image.

```shell
cd ./var/lib/registry
docker run -p 25000:5000 -v $(pwd):/var/lib/registry registry:2
# verify the registry mounted correctly
curl http://localhost:25000/v2/_catalog -k
# a list of Big Bang images should be displayed, if not check the volume mount of the registry
```

Configure `./synker.yaml`

Example

```yaml
destination:
  registry:
    # Hostname of the destination registry to push to
    hostname: 10.0.0.10
    # Port of the destination registry to push to
    port: 5000
```

If you are using runtime mirroring the new image should be available at the original location on your cluster.
