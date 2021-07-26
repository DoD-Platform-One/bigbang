# Development Environment overview

[[_TOC_]]

BigBang developers use [k3d](https://k3d.io/), a lightweight wrapper to run [k3s](https://github.com/rancher/k3s) (Rancher Lab’s minimal Kubernetes distribution) in docker.  

It is not recommend to run k3d with BigBang on your local computer. BigBang can be quite resource-intensive and it requires a huge download bandwidth for the images. It is best to use a remote k3d cluster running on an AWS EC2 instance. If you do insist on running k3d locally you should disable certain packages before deploying. You can do this in the values.yaml file by setting the package deploy to false. One of the packages that is most resource-intensive is the logging package. And you should create a local image registry cache to minimize the amount of image downloading. A script that shows how to create a local image cache is in the [BigBang Quick Start](https://repo1.dso.mil/platform-one/quick-start/big-bang/)

This page contains the manual steps to create your k3d dev environment. Various persons have automated parts of these steps with scripts and terraform but we recommend that you do it manually so that you understand how it works. Automation is left to each person. It might be helpful to get a live demonstration by someone who already knows how to do it until a good video tutorial is created. We strive to make the documentation as good as possible but it is hard to keep it up-to-date and there are still pitfalls and gotchas.

## Prerequisites

### Required Access

- [AWS GovCloud "coder" account](https://927962728993.signin.amazonaws-us-gov.com/console)
- [BigBang repository](https://repo1.dso.mil/platform-one/big-bang/bigbang)
- [Iron Bank registry](https://registry1.dso.mil/)

### Local Utilities

- [Helm](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)  

## Manual Creation of a Development Environment

This section will cover the creation of an environment manually. This is a good place to start because it creates an understanding of everything that the automated method does for you and uses far less cloud resources.

### Step 1

Create an Ubuntu EC2 instance using the AWS console with the following attributes. Please clean up after yourself. Stop or delete any instances that you are not currently using. See addendum for using Amazon Linux2 instead of Ubuntu. See addendum for using aws command line.

- Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
- t2.2xlarge
- IAM Role: InstanceOpsRole (This will add support for sops encryption with KMS)
- User Data (as Text):

```shell
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
    
--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
# Set the vm.max_map_count to 262144. 
# Required for Elastic to run correctly without OOM errors.
echo 'vm.max_map_count=524288' > /etc/sysctl.d/vm-max_map_count.conf
echo 'fs.file-max=131072' > /etc/sysctl.d/fs-file-max.conf
sysctl -p
ulimit -n 131072
ulimit -u 8192
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
```

- 50 Gigs of disk space
- Tags:  ```Name: <firstname.lastname>```
- Security Group: All TCP limited to your local IP address. If you already have a security group, select it.  Otherwise create a new one. See addendum for more secure way with only port 22 for ssh traffic using sshuttle.
- If you have created an existing key pair that you still have access to, select it. If not, create a new key pair. Be sure to save the pem file.  

### Step 2

Configure the EC2 instance. SSH into your new EC2 instance and configure it with the following:

- SSH: Find your instance's public IP. This may be in the output of your `run-instance` command, if not search for your instance id in the AWS web console and under the details copy your public ipv4 address. Example below assumes this value is `1.2.3.4`, replace that with the actual value.

```shell
EC2_PUBLIC_IP=1.2.3.4
ssh -i ~/.ssh/your-ec2.pem ubuntu@$EC2_PUBLIC_IP
```

- Install Docker CE

```shell
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
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add your base user to the Docker group so that you do not need sudo to run docker commands
sudo usermod -aG docker $USER

# It is important to log out and back in to have the user group changes take effect.
logout
```

- Install K3D on the EC2 instance

```shell
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
# check version
k3d version
```

- Start our dev cluster on the EC2 instance using K3D. See addendum for more secure way with only port 22 exposed using private ip and sshuttle & section to have support for multi istio ingressgateways with a K3D cluster using MetalLB.

```shell
EC2_PUBLIC_IP=$( curl https://ipinfo.io/ip )
echo $EC2_PUBLIC_IP

# Create k3d cluster
k3d cluster create \
    --servers 1 \
    --agents 3 \
    --volume /etc/machine-id:/etc/machine-id \
    --k3s-server-arg "--disable=traefik" \
    --k3s-server-arg "--disable=metrics-server" \
    --k3s-server-arg "--tls-san=$EC2_PUBLIC_IP" \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --api-port 6443
```

**_Optionally_** you can set your image pull secret on the cluster so that you don't have to put your credentials in the code or in the command line in later steps

```shell
# Create the directory for the k3s registry config.
mkdir ~/.k3d/

# Define variables
YOURUSERNAME="<user_name>"
YOURCLISECRET="<CLI secret>"
EC2_PUBLIC_IP=$( curl https://ipinfo.io/ip )

# Create the config file using your registry1 credentials.
cat << EOF > ~/.k3d/p1-registries.yaml
configs:
  "registry1.dso.mil":
    auth:
      username: $YOURUSERNAME
      password: $YOURCLISECRET
EOF

# Create k3d cluster
k3d cluster create \
    --servers 1 \
    --agents 3 \
    --volume ~/.k3d/p1-registries.yaml:/etc/rancher/k3s/registries.yaml \
    --volume /etc/machine-id:/etc/machine-id \
    --k3s-server-arg "--disable=traefik" \
    --k3s-server-arg "--disable=metrics-server" \
    --k3s-server-arg "--tls-san=$EC2_PUBLIC_IP" \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --api-port 6443
```

Here is an explanation of what we are doing with this command:

- `--servers 1` Creating 1 master/server
- `--agents 3` Creating 3 agent nodes
- `--k3s-server-arg "--disable=traefik"` Disable the default Traefik Ingress
- `--k3s-server-arg "--disable=metrics-server"` Disable default metrics
- `--k3s-server-arg "--tls-san=<your public ec2 ip>"` This adds the public IP to the kubeapi certificate so that you can access it remotely.
- `--port 80:80@loadbalancer` Exposes the cluster on the host on port 80
- `--port 443:443@loadbalancer` Exposes the cluster on the host on port 443
- `--volume ~/.k3d/p1-registries.yaml:/etc/rancher/k3s/registries.yaml` volume mount image pull secret config for k3d cluster.
- `--volume /etc/machine-id:/etc/machine-id` volume mount so k3d nodes have a file at /etc/machine-id for fluentbit DaemonSet.
- `--api-port 6443` port that your k8s api will use. 6443 is the standard default port for k8s api

### Step 3

Test the cluster from your local workstation. Copy the contents of the k3d kubeconfig from the EC2 instance to your local workstation. Do it manually with copy and paste.

```shell
# on the EC2 instance
echo $EC2_PUBLIC_IP
cat ~/.kube/config
```

Or, use secure copy to move it to your workstation. example:

```shell
scp -i ~/.ssh/your-ec2.pem ubuntu@$EC2_PUBLIC_IP:~/.kube/config ~/.kube/config
```

Edit the kubeconfig on your workstation. Replace the server host ```0.0.0.0``` with with the public IP of the EC2 instance. Test cluster access from your local workstation.

```shell
kubectl cluster-info
kubectl get nodes
```

### Step 4

Start deploying to your k3d cluster. The scope of this documentation is limited to creating your dev environment. How to deploy BigBang is intentionally NOT included here. Those steps are left to other documents. You will need to install flux in your cluster before deploying BigBang.

```shell
# git clone the bigbang repo somewhere on your workstation
git clone https://repo1.dso.mil/platform-one/big-bang/bigbang.git
# run the script to install flux in your cluster using your registry1.dso.mil image pull credentials
cd ./bigbang
./scripts/install_flux.sh -u your-user-name -p your-pull-secret
```

## Addendum

### More secure method with `sshuttle`

Instead of opening all TCP traffic (all ports) to your local public ip address you only need port 22 for ssh traffic. And then use sshuttle to tunnel into your EC2 instance. Here is an example assuming that your EC2 is in the default VPC. All other steps being the same as above.

```shell
# ssh to your EC2 instance using the public IP. For Amazon Linux 2 the user is "ec2-user"
ssh -i ~/.ssh/your-ec2.pem ubuntu@$EC2_PUBLIC_IP

# set environment variable for private IP
EC2_PRIVATE_IP=$(hostname -I | awk '{print $1}')

# create the k3d cluster with SAN for private IP
# Create k3d cluster
k3d cluster create \
    --servers 1 \
    --agents 3 \
    --volume ~/.k3d/p1-registries.yaml:/etc/rancher/k3s/registries.yaml \
    --volume /etc/machine-id:/etc/machine-id \
    --k3s-server-arg "--disable=traefik" \
    --k3s-server-arg "--disable=metrics-server" \
    --k3s-server-arg "--tls-san=$EC2_PRIVATE_IP" \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --api-port 6443
```

Then on your workstation edit the kubeconfig with the EC2 private ip. In a separate terminal window start a tunnel session with sshuttle using the EC2 public IP.

```shell
sshuttle --dns -vr ec2-user@$EC2_PUBLIC_IP 172.31.0.0/16 --ssh-cmd 'ssh -i ~/.ssh/your-ec2.pem'
```

### Multi Ingress-gateway Support with MetalLB and K3D

1. If you want to utilize BigBang's multi ingress-gateway support for istio, it is possible with K3D but requires some different flags at cluster creation.

```shell
# ssh to your EC2 instance using the public IP. For Amazon Linux 2 the user is "ec2-user"
ssh -i ~/.ssh/your-ec2.pem ubuntu@$EC2_PUBLIC_IP

# set environment variable for private IP
EC2_PRIVATE_IP=$(hostname -I | awk '{print $1}')

# create the k3d cluster with SAN for private IP
# Create k3d cluster
k3d cluster create \
    --servers 1 \
    --agents 3 \
    --volume ~/.k3d/p1-registries.yaml:/etc/rancher/k3s/registries.yaml \
    --volume /etc/machine-id:/etc/machine-id \
    --k3s-server-arg "--disable=traefik" \
    --k3s-server-arg "--disable=metrics-server" \
    --k3s-server-arg "--disable=servicelb" \
    --k3s-server-arg "--tls-san=$EC2_PRIVATE_IP" \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --api-port 6443
```
  - This will create a K3D cluster just like before, except we need to ensure the built in "servicelb" add-on is disabled so we can use metallb.

2. Find the Subnet for your k3d cluster's Docker network

```shell
docker network inspect k3d-k3s-default | jq .[0].IPAM.Config[0]
```

  - k3d-k3s-default is the name of the default bridge network k3d creates when creating a k3d cluster.
  - We need the "Subnet": value to populate the correct addresses in the ConfigMap below.
  - If my output looks like:
  ```json
  {
    "Subnet": "172.21.0.0/16",
    "Gateway": "172.21.0.1"
  }
  ```
  - Then the addresses I want to input for metallb would be `172.21.1.240-172.21.1.243` so that I can reserve 4 IP addresses within the subnet of the Docker Network.

3. Before installing BigBang we will need to install and configure [metallb](https://metallb.universe.tf/concepts/)

```shell
kubectl create -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl create -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
cat <<EOF | > metallb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.21.1.240-172.21.1.243
EOF
kubectl create -f metallb-config.yaml
```

  - The commands will create a metallb install and configure it to assign LoadBalancer IPs within the range `172.18.1.240-172.18.1.243` which is within the standard Docker Bridge Network CIDR meaning that the linux network stack will have a route to this network already.

4. Verify LoadBalancers

```shell
kubectl get svc -n istio-system
```

  - You should see a result like:
```
NAME                         TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                                                      AGE
istiod                       ClusterIP      10.43.59.25    <none>         15010/TCP,15012/TCP,443/TCP,15014/TCP                        151m
private-ingressgateway       LoadBalancer   10.43.221.12   172.18.1.240   15021:31000/TCP,80:31001/TCP,443:31002/TCP,15443:31003/TCP   150m
public-ingressgateway        LoadBalancer   10.43.35.202   172.18.1.241   15021:30000/TCP,80:30001/TCP,443:30002/TCP,15443:30003/TCP   150m
passthrough-ingressgateway   LoadBalancer   10.43.173.31   172.18.1.242   15021:32000/TCP,80:32001/TCP,443:32002/TCP,15443:32003/TCP   119m
```

  - With the key information here being the assigned `EXTERNAL-IP` sections for the ingressgateways.

5. Update Hosts file on ec2 instance with IPs above

```shell
sudo vim /etc/hosts
```

  - Update it with similar entries:
    - Applications with the following values (eg for Jaeger):
    ```yaml
    jaeger:
      ingress:
        gateway: "" #(Defaults to public-ingressgateway)
    ```
    We will need to set to the EXTERNAL-IP of the public-ingressgateway
    ```
    172.18.1.241 jaeger.bigbang.dev
    ```
    - Applications with the following values (eg for Logging):
    ```yaml
    logging:
      ingress:
        gateway: "private"
    ```
    We will need to set to the EXTERNAL-IP of the private-ingressgateway
    ```
    172.18.1.240 kibana.bigbang.dev
    ```
    - Keycloak will need to be set to the External-IP of the passthrough-ingressgateway
    ```
    172.18.1.242 keycloak.bigbang.dev
    ```
  - With these DNS settings in place you will now be able to reach the external *.bigbang.dev URLs from this EC2 instance.

  - To reach outside the EC2 instance use either SSH or SSHUTTLE commands to specify a local port for Dynamic application-level port forwarding (ssh -D) and utilize Firefox's built in SOCKS proxy configuration to route DNS and web traffic through the application-level port forward from the SSH command.

### Amazon Linux 2

Here are the configuration steps if you want to use a Fedora based instance. All other steps are similar to Ubuntu.

```shell
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

### AWS CLI commands to manually create EC2 instance

```shell
# install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

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
    --description "Created by $AWSUSERNAME at $DATETIME"

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
