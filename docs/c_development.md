# Appendix C - Big Bang Development

## So you want to develop on Big Bang?

Included here is a setup that will allow you to checkout and begin development using your workstation and a minimal EC2 instance in AWS.

### Prequisites

#### Access

- [AWS GovCloud (US) EC2](https://console.amazonaws-us-gov.com/ec2)
- [Umbrella repository](https://repo1.dsop.io/platform-one/big-bang/umbrella)
- [Iron Bank registry](https://registry1.dsop.io/)

#### Utilities

- kubectl installed on local machine. This will also need to be installed on the remote if you wish to verify the K3D cluster using `kubectl cluster-info`

```bash
# Install kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubectl
kubectl version --client
```

- yq installed on local machine

```bash
# Install yq
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
sudo add-apt-repository ppa:rmescandon/yq -y
sudo apt update && sudo apt install yq -y
yq --version
```

- Flux CLI installed on your local machine

```bash
curl -s https://toolkit.fluxcd.io/install.sh | sudo bash
flux --version
```

- AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Manual Creation of a Development Environment

This section will cover the creation of an environment manually. This is a good place to start because it creates an understanding of everything that the automated method does for you.

Step 1: Create an Ubuntu EC2 instance with the following attributes:

```bash

# Note: There is an issue with aws configure import, configuration is manual.
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/configure/import.html
# https://github.com/aws/aws-cli/issues/1201#issuecomment-642131086
# https://console.amazonaws-us-gov.com/iam/home?region=us-gov-west-1#/security_credentials

# aws configure
# aws_access_key_id - The AWS access key part of your credentials
# aws_secret_access_key - The AWS secret access key part of your credentials
# region - us-gov-west-1
# output - JSON

# Verify configuration
aws configure list

# Set variables
AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )

# Disable local pager
export AWS_PAGER=""

# Recreate key pair
rm -f $AWSUSERNAME.pem
aws ec2 delete-key-pair --key-name $AWSUSERNAME
aws ec2 create-key-pair --key-name $AWSUSERNAME --query 'KeyMaterial' --output text > $AWSUSERNAME.pem
chmod 400 $AWSUSERNAME.pem

# Verify private key
openssl rsa -noout -inform PEM -in $AWSUSERNAME.pem
aws ec2 describe-key-pairs --key-name $AWSUSERNAME

# Get InstanceId
AWSINSTANCEID=$( aws ec2 describe-instances \
    --output text \
    --query "Reservations[].Instances[].InstanceId" \
    --filters "Name=tag:Owner,Values=$AWSUSERNAME" "Name=tag:env,Values=bigbangdev" )

# Terminate existing instance
aws ec2 terminate-instances --instance-ids $AWSINSTANCEID

# Delete old Security Group
aws ec2 delete-security-group --group-name=$AWSUSERNAME

# Get current datetime
DATETIME=$( date +%Y%m%d%H%M%S )

# Create new Security Group
# A security group acts as a virtual firewall for your instance to control inbound and outbound traffic.
aws ec2 create-security-group \
    --group-name $AWSUSERNAME \
    --description "Created by $AWSUSERNAME at $DATETIME" \

# Get public IP
YOURLOCALPUBLICIP=$( curl https://checkip.amazonaws.com )

# Add rule to security group
aws ec2 authorize-security-group-ingress \
     --group-name $AWSUSERNAME \
     --protocol tcp \
     --port 0-65535 \
     --cidr $YOURLOCALPUBLICIP/32

# Create userdata.txt
# https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/
cat << EOF > userdata.txt
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

    --==MYBOUNDARY==
    Content-Type: text/x-shellscript; charset="us-ascii"

    #!/bin/bash
    # Set the vm.max_map_count to 262144.
    # Required for Elastic to run correctly without OOM errors.
    sysctl -w vm.max_map_count=262144
EOF

# Create new instance
aws ec2 run-instances \
    --image-id ami-84556de5 \
    --count 1 \
    --instance-type t2.xlarge \
    --key-name $AWSUSERNAME \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Owner,Value=$AWSUSERNAME},{Key=env,Value=bigbangdev}]" \
    --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=50}' \
    --iam-instance-profile Name="InstanceOpsRole" \
    --security-groups $AWSUSERNAME \
    --user-data file://userdata.txt
```

Step 2: SSH into your new EC2 instance and configure it with the following:

- Install Docker CE

```bash
# Remove any old Docker items
sudo apt remove docker docker-engine docker.io containerd runc

# Install all pre-reqs for Docker
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

# Add the Docker repository, we are installing from Docker and not the Ubuntu APT repo.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add your base user to the Docker group so that you do not need sudo to run docker commands
sudo usermod -aG docker $USER

# It is important to log out and back in to have the user group changes take effect.
logout
```

- Install K3D on the EC2 instance

```bash
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
k3d version
```

- We can now spin up our dev cluster on the EC2 instance using K3D

```bash
YOURPUBLICEC2IP=$( curl https://ipinfo.io/ip )
echo $YOURPUBLICEC2IP
k3d cluster create -s 1 -a 3  --k3s-server-arg "--disable=traefik" --k3s-server-arg "--disable=metrics-server" --k3s-server-arg "--tls-san=$YOURPUBLICEC2IP"  -p 80:80@loadbalancer -p 443:443@loadbalancer
```

- **_Optionally_** you can set your image pull secret on the cluster so that you don't have to put your credentials in the code or in the command line in later steps

```bash
# Create the directory for the k3s registry config.
mkdir ~/.k3d/

# Create the config file. Use your registry1 credentials. Copy your user name and token secret from your Harbor profile.
cat << EOF > ~/.k3d/p1-registries.yaml
configs:
  "registry1.dsop.io":
    auth:
      username: "user.name"
      password: "place_token_secret_here"
EOF

YOURPUBLICEC2IP=$( curl https://ipinfo.io/ip )
k3d cluster create --servers 1 --agents 3 -v ~/.k3d/p1-registries.yaml:/etc/rancher/k3s/registries.yaml --k3s-server-arg "--disable=traefik" --k3s-server-arg "--disable=metrics-server" --k3s-server-arg "--tls-san=$YOURPUBLICEC2IP"  -p 80:80@loadbalancer -p 443:443@loadbalancer
```

Here is a break down of what we are doing with this command:

- `-s 1` Creating 1 master/server
- `-a 3` Creating 3 agent nodes
- `--k3s-server-arg "--disable=traefik"` Disable the default Traefik Ingress
- `--k3s-server-arg "--disable=metrics-server"` Disable default metrics
- `--k3s-server-arg "--tls-san=<your public ec2 ip>"` This adds the public IP to the kubeapi certificate so that you can access it remotely.
- `-p 80:80@loadbalancer` Exposes the cluster on the host on port 80
- `-p 443:443@loadbalancer` Exposes the cluster on the host on port 443

optional:
`-v ~/.k3d/p1-registries.yaml:/etc/rancher/k3s/registries.yaml` volume mount image pull secret config for k3d cluster
`--api-port 0.0.0.0:38787` Chooses a port for the API server instead of being assigned a random one. You can set this to any port number that you want.

- Once your cluster is up, you can copy the kubeconfig from the EC2 instance to your workstation and update the IP Address. If you do not have an existing configuration to preserve on your local workstation, you can delete and recreate the configuration file.

Copy the contents of the remote configuation file.

```bash
cat ~/.kube/config
```

- Move to your workstation and setup namespace

Update the configuration file on your local workstation.

```bash
# Remove existing configuation if defined.
rm ~/.kube/config

# Create empty configuation
touch ~/kube/config

# Update permissions
# (Prevents Helm warnings)
chmod go-r ~/.kube/config

# Open vi to edit configuation
vi ~/.kube/config
```

Paste the contents into the new file, and update the `server` URL to the public IP address (`$YOURPUBLICEC2IP`).

```bash
# Test to see if you can connect to your cluster
kubectl cluster-info
kubectl get nodes

# Create Project base

mkdir -pv ~/repos/
cd ~/repos
git clone https://repo1.dsop.io/platform-one/big-bang/umbrella.git
cd ~/repos/umbrella
```

From the base of the project

```bash
# Flux - Install the toolkit components
flux install

# kubectl - Create a namespace with the specified name.
kubectl create ns bigbang
```

- Customize your Helm values

```bash
# You will be overriding values in `chart/values.yaml` for development
# You can use the [Big Bang template's dev ConfigMap](https://repo1.dsop.io/platform-one/big-bang/customers/bigbang/-/blob/template/bigbang/dev/configmap.yaml) to start.  This will minimize the resources for deploying BigBang.
# For convenience, it is also copied here

cat << EOF > my-values.yaml
hostname: bigbang.dev
flux:
  interval: 1m
  rollback:
    cleanupOnFail: false
gatekeeper:
  values:
    replicas: 1
istio:
  values:
    kiali:
      dashboard:
        auth:
          strategy: anonymous
    ingressGateway:
      serviceAnnotations:
        # Ensure mission apps have internal load balancer only
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        # Enable cross zone load balancing
        service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
logging:
  values:
    elasticsearch:
      master:
        count: 1
        persistence:
          size: 5Gi
        resources:
          limits:
            cpu: 1
            memory: 3Gi
      data:
        count: 1
        persistence:
          size: 5Gi
        resources:
          limits:
            cpu: 1
            memory: 3Gi

twistlock:
  values:
    console:
      persistence:
        size: 5Gi
EOF

# Add any additional development values to this file as needed
# You can add registry1 pull credentials here for development
# Examples included enabling add-ons, disabling unneeded features, etc.
```

- Deploy secrets

```bash
# These are all OPTIONAL.  Deploy them if you need them

# Deploy the bigbang-dev.asc SOPS key into the bigbang namespace
./hack/sops-create.sh

# Deploy the authservice configuration
sops -d ./hack/secrets/authservice-config.yaml | kubectl apply -f -

# Deploy the ingress certificates
sops -d ./hack/secrets/ingress-cert.yaml | kubectl apply -f -

# Apply tests CI shared secrets
kubectl apply -f tests/ci/shared-secrets.yaml
```

- Install BigBang using Iron Bank (Harbor) credentials.

```bash
# Helm install BigBang
helm upgrade -i bigbang chart -n bigbang --create-namespace --set registryCredentials.username='<your user>' --set registryCredentials.password=<your cli key> -f my-values.yaml
```

- You can now modify your local `/etc/hosts` file to allow for local name resolution. On Windows, this file is located at `$env:windir\System32\drivers\etc\hosts`

```HOSTS
<X.X.X.X>     kibana.bigbang.dev
<X.X.X.X>     kiali.bigbang.dev
<X.X.X.X>     prometheus.bigbang.dev
<X.X.X.X>     graphana.bigbang.dev
```

- You can watch your install take place with

```bash
# macOS does not include watch
# recommend install with brew
# brew install watch

watch kubectl get po,gitrepository,kustomizations,helmreleases -A
```

As of this time, Twistlock is the last thing to be installed. Once you see Twistlock sync and everything else is up and healty you are fully installed.

### Addendum for Amazon Linux 2

Here are the configuration steps if you want to use a Fedora based instance. All other steps are similar to Ubuntu.

```bash
# update system
sudo yum update -y

# install and start docker
sudo yum install docker -y
sudo usermod -aG docker $USER
sudo systemctl enable docker.service
sudo systemctl start docker.service

# fix docker config for ulimit nofile.
# this is a bug in the AMI that will eventually be fixed
sudo sed -i 's/^OPTIONS=.*/OPTIONS=\"--default-ulimit nofile=65535:65535\"/' /etc/sysconfig/docker
sudo systemctl restart docker.service

# install k3d
sudo wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash

# exit ssh and then reconnect so you can use docker as non-root
```
