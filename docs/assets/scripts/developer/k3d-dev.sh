#!/bin/bash

#### Preflight Checks
# check for tools
tooldependencies=(jq sed aws ssh ssh-keygen scp kubectl)
for tooldependency in "${tooldependencies[@]}"
  do
    command -v $tooldependency >/dev/null 2>&1 || { echo >&2 " $tooldependency is not installed.";  missingtool=1; }
  done
sed_gsed="sed"
# verify sed version if mac
uname="$(uname -s)"
if [[ "${uname}" == "Darwin" ]]; then
  if [[ $(command -v gsed) ]]; then
    sed_gsed="gsed"
  else
    missingtool=1
    echo ' gnu-sed is not installed. "brew install gnu-sed"'
  fi
fi
# if tool missing, exit
if [[ "${missingtool}" == 1 ]]; then
  echo " Please install required tools. Aborting."
  exit 1
fi

# getting AWs user name
AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )

# check for aws username environment variable. If not found then terminate script
if [[ -z "${AWSUSERNAME}" ]]; then
  echo "You must configure your AWS credentials. Your AWS user name is used to name resources in AWS. Example:"
  echo "   aws configure"
  exit 1
else
    echo "AWS User Name: ${AWSUSERNAME}"
fi


####Configure Environment
# Assign a name for your SSH Key Pair.  Typically, people use their username to make it easy to identify
KeyName="${AWSUSERNAME}-dev"
# Assign a name for your Security Group.  Typically, people use their username to make it easy to identify
SGname="${AWSUSERNAME}-dev"
# Identify which VPC to create the spot instance in
VPC="vpc-2ffbd44b"  # default VPC


while [ -n "$1" ]; do # while loop starts

  case "$1" in

  -b) echo "-b option passed for big k3d cluster using M5 instance" 
      BIG_INSTANCE=true
  ;;

  -p) echo "-p option passed to create k3d cluster with private ip" 
      PRIVATE_IP=true
  ;;

  -m) echo "-m option passed to install MetalLB" 
      METAL_LB=true
  ;; 

  -d) echo "-d option passed to destroy the AWS resources"
      AWSINSTANCEIDs=$( aws ec2 describe-instances \
        --output text \
        --query "Reservations[].Instances[].InstanceId" \
        --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=instance-state-name,Values=running" )
      # If instance exists then terminate it 
      if [[ ! -z "${AWSINSTANCEIDs}" ]]; then 
        echo "aws instances being terminated: ${AWSINSTANCEIDs}"
        
        read -p "Are you sure you want to delete these instances (y/n)? " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          echo
          exit 1
        fi

        aws ec2 terminate-instances --instance-ids ${AWSINSTANCEIDs} &>/dev/null
        echo -n "waiting for instance termination..."
        aws ec2 wait instance-terminated --instance-ids ${AWSINSTANCEIDs} &> /dev/null
        echo "done"
      else
        echo "You had no running instances."
      fi
      echo "SecurityGroup name to be deleted: ${SGname}"
      aws ec2 delete-security-group --group-name=${SGname} &> /dev/null
      echo "KeyPair to be deleted: ${KeyName}"
      aws ec2 delete-key-pair --key-name ${KeyName} &> /dev/null
      exit 0 
  ;;

  -h) echo "Usage:"
      echo "k3d-dev.sh -b -p -m -d -h"
      echo ""
      echo " -b   use BIG M5 instance. Default is t3.2xlarge"
      echo " -p   use private IP for security group and k3d cluster"
      echo " -m   create k3d cluster with metalLB"
	  echo " -d   destroy related AWS resources"
      echo " -h   output help"
      exit 0
  ;;

  *) echo "Option $1 not recognized" ;; # In case a non-existant option is submitted

  esac
  shift
done


if [[ "$BIG_INSTANCE" == true ]]
then 
  echo "Will use large m5a.4xlarge spot instance"
  InstSize="m5a.4xlarge"
  SpotPrice="0.69"
else
  echo "Will use standard t3a.2xlarge spot instance"
  InstSize="t3a.2xlarge"
  SpotPrice="0.35"
fi


#### SSH Key Pair
# Create SSH key if it doesn't exist
echo -n Checking if key pair ${KeyName} exists ...
aws ec2 describe-key-pairs --output json --no-cli-pager --key-names ${KeyName} > /dev/null 2>&1 || keypair=missing
if [ "${keypair}" == "missing" ]; then
  echo -n -e "missing\nCreating key pair ${KeyName} ... "
  aws ec2 create-key-pair --output json --no-cli-pager --key-name ${KeyName} | jq -r '.KeyMaterial' > ~/.ssh/${KeyName}.pem
  chmod 600 ~/.ssh/${KeyName}.pem
  echo done
else
  echo found
fi


#### Security Group
# Create security group if it doesn't exist
echo -n "Checking if security group ${SGname} exists ..."
aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} > /dev/null 2>&1 || secgrp=missing
if [ "${secgrp}" == "missing" ]; then
  echo -e "missing\nCreating security group ${SGname} ... "
  aws ec2 create-security-group --output json --no-cli-pager --description "IP based filtering for ${SGname}" --group-name ${SGname} --vpc-id ${VPC}
  echo done
else
  echo found
fi

# Lookup the security group created to get the ID
echo -n Retrieving ID for security group ${SGname} ...
SecurityGroupId=$(aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} --query "SecurityGroups[0].GroupId" --output text)
echo done

# Add name tag to security group
aws ec2 create-tags --resources ${SecurityGroupId} --tags Key=Name,Value=${SGname} &> /dev/null


# Add rule for IP based filtering
WorkstationIP=`curl http://checkip.amazonaws.com/ 2> /dev/null`
echo -n Checking if ${WorkstationIP} is authorized in security group ...
aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} | grep ${WorkstationIP} > /dev/null || ipauth=missing
if [ "${ipauth}" == "missing" ]; then
  echo -e "missing\nAdding ${WorkstationIP} to security group ${SGname} ..."
  if [[ "$PRIVATE_IP" == true ]];
	then
	  	aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol tcp --port 22 --cidr ${WorkstationIP}/32
	else  # all protocols to all ports is the default
		aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol all --cidr ${WorkstationIP}/32
	fi
  echo done
else
  echo found
fi


##### Launch Specification
# Typical settings for Big Bang development
AMIName="ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"
InstanceType="${InstSize}"
VolumeSize=120

# Lookup the image name to find the latest version
# echo -n Retrieving latest image ID matching ${AMIName} ...
# ImageId=$(aws ec2 describe-images --output json --no-cli-pager --filters "Name=name,Values=${AMIName}" --query "reverse(sort_by(Images, &CreationDate))[:1].ImageId" --output text)
#echo done
# Hardcode the latest image instead of searching for it to avoid unexpected changes
echo Using AMI image id ami-84556de5
ImageId=ami-84556de5

# Create the launch spec
echo -n Creating launch_spec.json ...
mkdir -p ~/aws
##notworking line.  "InstanceInitiatedShutdownBehavior":"Terminate",
cat << EOF > ~/aws/launch_spec.json
{
  "ImageId": "${ImageId}",
  "InstanceType": "${InstanceType}",
  "KeyName": "${KeyName}",
  "SecurityGroupIds": [ "${SecurityGroupId}" ],
  "BlockDeviceMappings": [
    {
      "DeviceName": "/dev/sda1",
      "Ebs": {
        "DeleteOnTermination": true,
        "VolumeType": "gp2",
        "VolumeSize": ${VolumeSize}
      }
    }
  ]
}
EOF

# TODO: can spot instances be created with userdata?
# Create userdata.txt
# https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/
cat << EOF > ~/aws/userdata.txt
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
EOF


#### Request a Spot Instance
# Location of your private SSH key created during setup
PEM=~/.ssh/${KeyName}.pem

# Request a spot instance with our launch spec for the max. of 6 hours
# NOTE: t3a.2xlarge spot price is 0.35 m5a.4xlarge is 0.69
echo Requesting spot instance ...
#Old spot request
#SIR=`aws ec2 request-spot-instances \
#  --output json --no-cli-pager \
#  --instance-count 1 \
##broken**  --attribute InstanceInitiatedShutdownBehavior=Terminate \
##  --instance-initiated-shutdown-behavior terminate \
#  --block-duration-minutes 360 \
#  --type "one-time" \
#  --spot-price "${SpotPrice}" \
#  --launch-specification file://$HOME/aws/launch_spec.json \
#  | jq -r '.SpotInstanceRequests[0].SpotInstanceRequestId'`
SIR=`aws ec2 request-spot-instances \
  --output json --no-cli-pager \
  --instance-count 1 \
  --type "one-time" \
  --spot-price "${SpotPrice}" \
  --launch-specification file://$HOME/aws/launch_spec.json \
  | jq -r '.SpotInstanceRequests[0].SpotInstanceRequestId'`

# Check if spot instance request was not created
if [ -z ${SIR} ]; then
  exit 1;
fi

# Request was created, now you need to wait for it to be filled
echo Waiting for spot instance request ${SIR} to be fulfilled ...
aws ec2 wait spot-instance-request-fulfilled --output json --no-cli-pager --spot-instance-request-ids ${SIR} &> /dev/null

# Get the instanceId
InstId=`aws ec2 describe-spot-instance-requests --output json --no-cli-pager --spot-instance-request-ids ${SIR} | jq -r '.SpotInstanceRequests[0].InstanceId'`

# Add name tag to spot instance
aws ec2 create-tags --resources ${InstId} --tags Key=Name,Value=${AWSUSERNAME}-dev  &> /dev/null

# Request was fulfilled, but instance is still spinng up, so wait on that
echo Waiting for instance ${InstId} to be ready ...
aws ec2 wait instance-running --output json --no-cli-pager --instance-ids ${InstId} &> /dev/null

# allow some extra seconds for the instance to be fully initiallized
echo "Wait a little longer..."
sleep 15

# Get the public IP address of our instance
PublicIP=`aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PublicIpAddress'`

# Get the private IP address of our instance
PrivateIP=`aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PrivateIpAddress'`

echo
echo "Instance ${InstId} is ready!"
echo "Instance private IP is ${PrivateIP}"
echo "Instance public IP is ${PublicIP}"
echo

# Remove previous keys related to this IP from your SSH known hosts so you don't end up with a conflict
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${PublicIP}"

echo "ssh init"
# this is a do-nothing remote ssh command just to initialize ssh and make sure that the connection is working
until ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "hostname"; do
  sleep 5
  echo "Retry ssh command.."
done
echo

##### Configure Instance
## TODO: replace these individual commands with userdata when the spot instance is created?
echo
echo
echo "starting instance config"
echo "Machine config"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo sysctl -w vm.max_map_count=524288"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c \"echo 'vm.max_map_count=524288' > /etc/sysctl.d/vm-max_map_count.conf\""
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c \"echo 'fs.file-max=131072' > /etc/sysctl.d/fs-file-max.conf\""
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c 'sysctl -p'"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c 'ulimit -n 131072'"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c 'ulimit -u 8192'"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c 'modprobe xt_REDIRECT'"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c 'modprobe xt_owner'"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c 'modprobe xt_statistic'"

echo "Instance will automatically terminate at 08:00 UTC"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo bash -c \"echo '0 8 * * * /usr/sbin/shutdown -h now' | crontab -\""
echo

echo
echo "installing packages"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo apt remove -y docker docker-engine docker.io containerd runc"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo apt -y update"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common"

echo
echo
# Add the Docker repository, we are installing from Docker and not the Ubuntu APT repo.
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo apt-key fingerprint 0EBFCD88"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} 'sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg'
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} 'echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list'


echo
echo
# Install Docker
echo "install Docker"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io kubectl jq tree vim"

echo
echo
# Add your base user to the Docker group so that you do not need sudo to run docker commands
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "sudo usermod -aG docker ubuntu"

echo
echo
# install k3d on instance
echo "Installing k3d on instance"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=v5.2.2 bash"
echo
echo "k3d version"
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "k3d version"
echo

echo "creating k3d cluster"

if [[ "$METAL_LB" == true ]]
then
  # create docker network for k3d cluster
  echo creating docker network for k3d cluster
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "docker network create k3d-network --driver=bridge --subnet=172.20.0.0/16"

  # create k3d cluster
  if [[ "$PRIVATE_IP" == true ]]
  then
    echo "using private ip for k3d"
    ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "k3d cluster create --servers 1  --agents 3 --volume /etc/machine-id:/etc/machine-id@server:0 --volume /etc/machine-id:/etc/machine-id@agent:0,1,2 --k3s-arg "--disable=traefik@server:0"  --k3s-arg "--disable=metrics-server@server:0" --k3s-arg "--tls-san=${PrivateIP}@server:0" --k3s-arg "--disable=servicelb@server:0" --network k3d-network --port 80:80@loadbalancer --port 443:443@loadbalancer --api-port 6443"
  else
    echo "using public ip for k3d"
    # default is to use public ip
    ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "k3d cluster create --servers 1  --agents 3 --volume /etc/machine-id:/etc/machine-id@server:0 --volume /etc/machine-id:/etc/machine-id@agent:0,1,2 --k3s-arg "--disable=traefik@server:0"  --k3s-arg "--disable=metrics-server@server:0" --k3s-arg "--tls-san=${PublicIP}@server:0" --k3s-arg "--disable=servicelb@server:0" --network k3d-network --port 80:80@loadbalancer --port 443:443@loadbalancer --api-port 6443"
  fi

  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl config use-context k3d-k3s-default"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl cluster-info"

  # install MetalLB
  echo installing MetalLB
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl create -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl create -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml"


  # create the metalLB config
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} <<- 'ENDSSH'
	#run this command on remote
	cat << EOF > metallb-config.yaml
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
	      - 172.20.1.240-172.20.1.243
	EOF
	ENDSSH

  # apply the metalLB config
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl create -f metallb-config.yaml"

  echo
  echo
  echo "copy kubeconfig"
  scp -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP}:/home/ubuntu/.kube/config ~/.kube/${AWSUSERNAME}-dev-config
  if [[ "$PRIVATE_IP" == true ]]
  then
    $sed_gsed -i "s/0\.0\.0\.0/${PrivateIP}/g" ~/.kube/${AWSUSERNAME}-dev-config
  else  # default is to use public ip
    $sed_gsed -i "s/0\.0\.0\.0/${PublicIP}/g" ~/.kube/${AWSUSERNAME}-dev-config
  fi
elif [[ "$PRIVATE_IP" == true ]]
then
  echo "using private ip for k3d"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "k3d cluster create --servers 1  --agents 3 --volume /etc/machine-id:/etc/machine-id@server:0 --volume /etc/machine-id:/etc/machine-id@agent:0,1,2 --k3s-arg "--disable=traefik@server:0"  --k3s-arg "--disable=metrics-server@server:0" --k3s-arg "--tls-san=${PrivateIP}@server:0" --port 80:80@loadbalancer --port 443:443@loadbalancer --api-port 6443"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl config use-context k3d-k3s-default"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl cluster-info"
  echo
  echo
  echo "copy kubeconfig"
  scp -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP}:/home/ubuntu/.kube/config ~/.kube/${AWSUSERNAME}-dev-config
  $sed_gsed -i "s/0\.0\.0\.0/${PrivateIP}/g" ~/.kube/${AWSUSERNAME}-dev-config

else # default is public ip
  echo "using public ip for k3d"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "k3d cluster create --servers 1  --agents 3 --volume /etc/machine-id:/etc/machine-id@server:0 --volume /etc/machine-id:/etc/machine-id@agent:0,1,2 --k3s-arg "--disable=traefik@server:0"  --k3s-arg "--disable=metrics-server@server:0" --k3s-arg "--tls-san=${PublicIP}@server:0" --port 80:80@loadbalancer --port 443:443@loadbalancer --api-port 6443"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl config use-context k3d-k3s-default"
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} "kubectl cluster-info"

  echo
  echo
  echo "copy kubeconfig"
  scp -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP}:/home/ubuntu/.kube/config ~/.kube/${AWSUSERNAME}-dev-config
  $sed_gsed -i "s/0\.0\.0\.0/${PublicIP}/g" ~/.kube/${AWSUSERNAME}-dev-config
fi

# add tools
echo Installing kubectl...
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} 'sudo mv /home/ubuntu/kubectl /usr/local/bin/'
ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} 'sudo chmod +x /usr/local/bin/kubectl'


if [[ "$METAL_LB" == true ]]; then
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no ubuntu@${PublicIP} <<- 'ENDSSH'
  # run this command on remote
  # fix /etc/hosts for new cluster
  sudo sed -i '/bigbang.dev/d' /etc/hosts
  sudo bash -c "echo '## begin bigbang.dev section' >> /etc/hosts"
  sudo bash -c "echo 172.20.1.240  keycloak.bigbang.dev >> /etc/hosts"
  sudo bash -c "echo 172.20.1.241  kiali.bigbang.dev >> /etc/hosts"
  sudo bash -c "echo 172.20.1.242  gitlab.bigbang.dev >> /etc/hosts"
  sudo bash -c "echo '## end bigbang.dev section' >> /etc/hosts"
	ENDSSH
fi

echo
echo "================================================================================"
echo "====================== DEPLOYMENT FINISHED ====================================="
echo "================================================================================"
# ending instructions
echo
echo "SAVE THE FOLLOWING INSTRUCTIONS INTO A TEMPORARY TEXT DOCUMENT SO THAT YOU DON'T LOOSE THEM"
echo "NOTE: The EC2 instance will automatically terminate at 08:00 UTC unless you delete the cron job"
echo
echo "ssh to instance:"
echo "ssh -i ~/.ssh/${KeyName}.pem ubuntu@${PublicIP}"
echo

if [[ "$METAL_LB" == true ]]
then
  if [[ "$PRIVATE_IP" == true ]]
  then
    echo "Start sshuttle:"
    echo "sshuttle --dns -vr ubuntu@${PublicIP} 172.31.0.0/16 --ssh-cmd 'ssh -i ~/.ssh/${KeyName}.pem -D 127.0.0.1:12345'"
  else  # using metal lb and public ip
    echo "To access apps from browser start ssh with application-level port forwarding:"
    echo "ssh -i ~/.ssh/${KeyName}.pem ubuntu@${PublicIP} -D 127.0.0.1:12345"
  fi
elif [[ "$PRIVATE_IP" == true ]]
then	
  echo "Start sshuttle:"
  echo "sshuttle --dns -vr ubuntu@${PublicIP} 172.31.0.0/16 --ssh-cmd 'ssh -i ~/.ssh/${KeyName}.pem'"
fi

echo
echo "To use kubectl from your local workstation you must set the KUBECONFIG environment variable:"
echo "export KUBECONFIG=~/.kube/${AWSUSERNAME}-dev-config"
echo

if [[ "$METAL_LB" == true ]]
then
  echo "Do not edit /etc/hosts on your local workstation."
  echo "To access apps from a browser edit /etc/hosts on the EC2 instance. Sample /etc/host entries have already been added there."
  echo "Manually add more hostnames as needed."
  echo "The IPs to use come from the istio-system services of type LOADBALANCER EXTERNAL-IP that are created when Istio is deployed."
  echo "You must use Firefox browser with with manual SOCKs v5 proxy configuration to localhost with port 12345."
  echo "Also ensure 'Proxy DNS when using SOCKS v5' is checked."
  echo "Or, with other browsers like Chrome you could use a browser plugin like foxyproxy to do the same thing as Firefox."
  echo
elif [[ "$PRIVATE_IP" == true ]]
then
  echo "To access apps from a browser edit your /etc/hosts to add the private IP of your instance with application hostnames. Example:"
  echo "${PrivateIP}	gitlab.bigbang.dev prometheus.bigbang.dev kibana.bigbang.dev"
  echo
else   # default is to use the public ip
  echo "To access apps from a browser edit your /etc/hosts to add the public IP of your instance with application hostnames."
  echo "Example:"
  echo "${PublicIP}	gitlab.bigbang.dev prometheus.bigbang.dev kibana.bigbang.dev"
  echo
fi
