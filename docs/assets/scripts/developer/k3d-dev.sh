#!/bin/bash

function run() {
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@${PublicIP} "$@"
}

#### Global variables - These allow the script to be run by non-bigbang devs easily
if [[ -z "${VPC_ID}" ]]; then
  # default
  VPC_ID=vpc-065ffa1c7b2a2b979
fi

if [[ -z "${AMI_ID}" ]]; then
  # default
  AMI_ID=$(aws ec2 describe-images --filters Name=owner-alias,Values=aws-marketplace Name=architecture,Values=x86_64 Name=name,Values="ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query 'sort_by(Images, &CreationDate)[].ImageId | [0]' --output text)
fi

#### Preflight Checks
# Check that the VPC is available 
EXISTING_VPC=$(aws ec2 describe-vpcs | grep ${VPC_ID})
if [[ -z "${EXISTING_VPC}" ]]; then
  echo "VPC is not available in the current AWS_PROFILE - Update VPC_ID"
  exit 1
fi
# check for tools
tooldependencies=(jq sed aws ssh ssh-keygen scp kubectl tr base64)
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
VPC="${VPC_ID}"  # default VPC
RESET_K3D=false

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

  *) echo "Option $1 not recognized" ;; # In case a non-existent option is submitted

  esac
  shift
done

echo "Checking for existing cluster for ${AWSUSERNAME}."
InstId=`aws ec2 describe-instances \
        --output text \
        --query "Reservations[].Instances[].InstanceId" \
        --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=instance-state-name,Values=running"`
  if [[ ! -z "${InstId}" ]]; then
    PublicIP=`aws ec2 describe-instances --output text --no-cli-pager --instance-id ${InstId} --query "Reservations[].Instances[].PublicIpAddress"`
    echo "Existing cluster found running on instance ${InstId} on ${PublicIP}"
    echo "💣 Big Bang Cluster Management 💣"
    PS3="Please select an option: "
    options=("Re-create K3D cluster" "Recreate the EC2 instance from scratch" "Quit")

    select opt in "${options[@]}"
    do
      case $REPLY in
        1)
          read -p "Are you sure you want to re-create a K3D cluster on this instance (y/n)? " -r
          if [[ ! $REPLY =~ ^[Yy]$ ]]
          then
            echo
            exit 1
          fi
          RESET_K3D=true
          run "k3d cluster delete"
          break;;
        2)
          read -p "Are you sure you want to destroy this instance ${InstId}, and create a new one in its place (y/n)? " -r
          if [[ ! $REPLY =~ ^[Yy]$ ]]
          then
            echo
            exit 1
          fi

          aws ec2 terminate-instances --instance-ids ${InstId} &>/dev/null
          echo -n "Instance is being terminated..."
          break;;
        3)
          echo "Bye."
          exit 0;;
        *)
          echo "Option $1 not recognized";;
      esac
    done
fi

if [[ "${RESET_K3D}" == false ]]; then
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
  InstanceType="${InstSize}"
  VolumeSize=120

  echo "Using AMI image id ${AMI_ID}"
  ImageId="${AMI_ID}"

  # Create userdata.txt
  mkdir -p ~/aws
  cat << EOF > ~/aws/userdata.txt
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
sudo -- bash -c 'sysctl -w vm.max_map_count=524288; \
echo "vm.max_map_count=524288" > /etc/sysctl.d/vm-max_map_count.conf; \
sysctl -w fs.nr_open=13181252; \
echo "fs.nr_open=13181252" > /etc/sysctl.d/fs-nr_open.conf; \
sysctl -w fs.file-max=13181250; \
echo "fs.file-max=13181250" > /etc/sysctl.d/fs-file-max.conf; \
echo "fs.inotify.max_user_instances=1024" > /etc/sysctl.d/fs-inotify-max_user_instances.conf; \
sysctl -w fs.inotify.max_user_instances=1024; \
echo "fs.inotify.max_user_watches=1048576" > /etc/sysctl.d/fs-inotify-max_user_watches.conf; \
sysctl -w fs.inotify.max_user_watches=1048576; \
echo "fs.may_detach_mounts=1" >> /etc/sysctl.d/fs-may_detach_mounts.conf; \
sysctl -w fs.may_detach_mounts=1; \
sysctl -p; \
echo "* soft nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
echo "* hard nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
echo "* soft nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
echo "* hard nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
modprobe br_netfilter; \
modprobe nf_nat_redirect; \
modprobe xt_REDIRECT; \
modprobe xt_owner; \
modprobe xt_statistic; \
echo "br_netfilter" >> /etc/modules-load.d/istio-iptables.conf; \
echo "nf_nat_redirect" >> /etc/modules-load.d/istio-iptables.conf; \
echo "xt_REDIRECT" >> /etc/modules-load.d/istio-iptables.conf; \
echo "xt_owner" >> /etc/modules-load.d/istio-iptables.conf; \
echo "xt_statistic" >> /etc/modules-load.d/istio-iptables.conf'
EOF

  # Create the device mapping and spot options JSON files
  echo "Creating device_mappings.json ..."
  mkdir -p ~/aws

  # gp3 volumes are 20% cheaper than gp2 and comes with 3000 Iops baseline and 125 MiB/s baseline throughput for free.
  cat << EOF > ~/aws/device_mappings.json
[
  {
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "DeleteOnTermination": true,
      "VolumeType": "gp3",
      "VolumeSize": ${VolumeSize},
      "Encrypted": true
    }
  }
]
EOF

  echo "Creating spot_options.json ..."
  cat << EOF > ~/aws/spot_options.json
{
  "MarketType": "spot",
  "SpotOptions": {
    "MaxPrice": "${SpotPrice}",
    "SpotInstanceType": "one-time"
  }
}
EOF

  #### Request a Spot Instance
  # Location of your private SSH key created during setup
  PEM=~/.ssh/${KeyName}.pem

  # Run a spot instance with our launch spec for the max. of 6 hours
  # NOTE: t3a.2xlarge spot price is 0.35 m5a.4xlarge is 0.69
  echo "Running spot instance ..."

  InstId=`aws ec2 run-instances \
    --output json --no-paginate \
    --count 1 --image-id "${ImageId}" \
    --instance-type "${InstanceType}" \
    --key-name "${KeyName}" \
    --security-group-ids "${SecurityGroupId}" \
    --instance-initiated-shutdown-behavior "terminate" \
    --user-data file://$HOME/aws/userdata.txt \
    --block-device-mappings file://$HOME/aws/device_mappings.json \
    --instance-market-options file://$HOME/aws/spot_options.json \
    | jq -r '.Instances[0].InstanceId'`

  # Check if spot instance request was not created
  if [ -z ${InstId} ]; then
    exit 1;
  fi

  # Add name tag to spot instance
  aws ec2 create-tags --resources ${InstId} --tags Key=Name,Value=${AWSUSERNAME}-dev &> /dev/null

  # Request was created, now you need to wait for it to be filled
  echo "Waiting for instance ${InstId} to be ready ..."
  aws ec2 wait instance-running --output json --no-cli-pager --instance-ids ${InstId} &> /dev/null

  # allow some extra seconds for the instance to be fully initiallized
  echo "Wait a little longer..."
  sleep 15

  # Get the public IP address of our instance
  PublicIP=`aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PublicIpAddress'`

  ##### Configure Instance
  ## TODO: replace these individual commands with userdata when the spot instance is created?
  echo
  echo
  echo "starting instance config"

  echo "Instance will automatically terminate 8 hours from now unless you alter the root crontab"
  run "sudo bash -c 'echo \"\$(date -u -d \"+8 hours\" +\"%M %H\") * * * /usr/sbin/shutdown -h now\" | crontab -'"
  echo

  echo
  echo "updating packages"
  run "sudo apt-get -y update"

  echo
  echo "installing docker"
  # install dependencies
  run "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release gnupg-agent software-properties-common"
  # Add the Docker repository, we are installing from Docker and not the Ubuntu APT repo.
  run 'sudo mkdir -m 0755 -p /etc/apt/keyrings'
  run 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg'
  run 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
  run "sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

  echo
  echo
  # Add your base user to the Docker group so that you do not need sudo to run docker commands
  run "sudo usermod -aG docker ubuntu"
  echo

  # install kubectl
  echo Installing kubectl...
  run 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
  run 'sudo mv /home/ubuntu/kubectl /usr/local/bin/'
  run 'sudo chmod +x /usr/local/bin/kubectl'

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
  until run "hostname"; do
    sleep 5
    echo "Retry ssh command.."
  done
  echo

  echo
  echo
  # install k3d on instance
  echo "Installing k3d on instance"
  run "wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=v5.4.9 bash"
  echo
  echo "k3d version"
  run "k3d version"
  echo

  echo "creating k3d cluster"
fi

# Shared k3d settings across all options
# 1 server, 3 agents
k3d_command="k3d cluster create --servers 1  --agents 3"
# Volumes to support Twistlock defenders
k3d_command+=" -v /etc:/etc@server:*\;agent:* -v /dev/log:/dev/log@server:*\;agent:* -v /run/systemd/private:/run/systemd/private@server:*\;agent:*"
# Disable traefik and metrics-server
k3d_command+=" --k3s-arg \"--disable=traefik@server:0\"  --k3s-arg \"--disable=metrics-server@server:0\""
# Port mappings to support Istio ingress + API access
k3d_command+=" --port 80:80@loadbalancer --port 443:443@loadbalancer --api-port 6443"

K3S_IMAGE_TAG=${K3S_IMAGE_TAG:=""}
if [[ ! -z "$K3S_IMAGE_TAG" ]]; then
  echo "Using custom K3S image tag $K3S_IMAGE_TAG..."
  k3d_command+=" --image docker.io/rancher/k3s:$K3S_IMAGE_TAG"
fi

# Add MetalLB specific k3d config
if [[ "$METAL_LB" == true ]]; then
  # create docker network for k3d cluster
  echo "creating docker network for k3d cluster"
  run "docker network create k3d-network --driver=bridge --subnet=172.20.0.0/16 --gateway 172.20.0.1"
  k3d_command+=" --k3s-arg \"--disable=servicelb@server:0\" --network k3d-network"
fi

# Add Public/Private IP specific k3d config
if [[ "$PRIVATE_IP" == true ]]; then
  echo "using private ip for k3d"
  k3d_command+=" --k3s-arg \"--tls-san=${PrivateIP}@server:0\""
else
  echo "using public ip for k3d"
  k3d_command+=" --k3s-arg \"--tls-san=${PublicIP}@server:0\""
fi

# Create k3d cluster
run "${k3d_command}"
run "kubectl config use-context k3d-k3s-default"
run "kubectl cluster-info"

# Handle MetalLB cluster resource creation
if [[ "$METAL_LB" == true ]]; then
  echo "installing MetalLB"
  run "kubectl create -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml"
	# Wait for controller to be live so that validating webhooks function when we apply the config
	echo "waiting for MetalLB controller"
	run "kubectl wait --for=condition=available --timeout 120s -n metallb-system deployment controller"

  run <<- 'ENDSSH'
	#run this command on remote
	cat << EOF > metallb-config.yaml
	apiVersion: metallb.io/v1beta1
	kind: IPAddressPool
	metadata:
	  name: default
	  namespace: metallb-system
	spec:
	  addresses:
	  - 172.20.1.240-172.20.1.243
	---
	apiVersion: metallb.io/v1beta1
	kind: L2Advertisement
	metadata:
	  name: l2advertisement1
	  namespace: metallb-system
	spec:
	  ipAddressPools:
	  - default
	EOF
	ENDSSH

  run "kubectl create -f metallb-config.yaml"
fi

echo "copying kubeconfig to workstation..."
scp -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@${PublicIP}:/home/ubuntu/.kube/config ~/.kube/${AWSUSERNAME}-dev-config
if [[ "$PRIVATE_IP" == true ]]; then
  $sed_gsed -i "s/0\.0\.0\.0/${PrivateIP}/g" ~/.kube/${AWSUSERNAME}-dev-config
else  # default is to use public ip
  $sed_gsed -i "s/0\.0\.0\.0/${PublicIP}/g" ~/.kube/${AWSUSERNAME}-dev-config
fi

if [[ "$METAL_LB" == true ]]; then
  run <<- 'ENDSSH'
  # run this command on remote
  # fix /etc/hosts for new cluster
  sudo sed -i '/bigbang.dev/d' /etc/hosts
  sudo bash -c "echo '## begin bigbang.dev section' >> /etc/hosts"
  sudo bash -c "echo 172.20.1.240  keycloak.bigbang.dev vault.bigbang.dev >> /etc/hosts"
  sudo bash -c "echo 172.20.1.241 anchore-api.bigbang.dev anchore.bigbang.dev argocd.bigbang.dev gitlab.bigbang.dev registry.bigbang.dev tracing.bigbang.dev kiali.bigbang.dev kibana.bigbang.dev chat.bigbang.dev minio.bigbang.dev minio-api.bigbang.dev alertmanager.bigbang.dev grafana.bigbang.dev prometheus.bigbang.dev nexus.bigbang.dev sonarqube.bigbang.dev tempo.bigbang.dev twistlock.bigbang.dev >> /etc/hosts"
  sudo bash -c "echo '## end bigbang.dev section' >> /etc/hosts"
  # run kubectl to add keycloak and vault's hostname/IP to the configmap for coredns, restart coredns
  kubectl get configmap -n kube-system coredns -o yaml | sed '/^    172.20.0.1 host.k3d.internal$/a\ \ \ \ 172.20.1.240 keycloak.bigbang.dev vault.bigbang.dev' | kubectl apply -f -
  kubectl delete pod -n kube-system -l k8s-app=kube-dns
	ENDSSH
fi

echo
echo "================================================================================"
echo "====================== DEPLOYMENT FINISHED ====================================="
echo "================================================================================"
# ending instructions
echo
echo "SAVE THE FOLLOWING INSTRUCTIONS INTO A TEMPORARY TEXT DOCUMENT SO THAT YOU DON'T LOSE THEM"
echo "NOTE: The EC2 instance will automatically terminate 8 hours from the time of creation unless you delete the root cron job"
echo
echo "ssh to instance:"
echo "  ssh -i ~/.ssh/${KeyName}.pem -o IdentitiesOnly=yes ubuntu@${PublicIP}"
echo
echo "To use kubectl from your local workstation you must set the KUBECONFIG environment variable:"
echo "  export KUBECONFIG=~/.kube/${AWSUSERNAME}-dev-config"
if [[ "$PRIVATE_IP" == true ]]
then
  echo "The cluster connection will not work until you start sshuttle as described below."
fi
echo

if [[ "$METAL_LB" == true ]] # using MetalLB
then
  if [[ "$PRIVATE_IP" == true ]]
  then   # using MetalLB and private IP
    echo "Start sshuttle in a separate terminal window:"
    echo "  sshuttle --dns -vr ubuntu@${PublicIP} 172.31.0.0/16 --ssh-cmd 'ssh -i ~/.ssh/${KeyName}.pem -D 127.0.0.1:12345'"
    echo "Do not edit /etc/hosts on your local workstation."
    echo "Edit /etc/hosts on the EC2 instance. Sample /etc/host entries have already been added there."
    echo "Manually add more hostnames as needed."
    echo "The IPs to use come from the istio-system services of type LOADBALANCER EXTERNAL-IP that are created when Istio is deployed."
    echo "You must use Firefox browser with with manual SOCKs v5 proxy configuration to localhost with port 12345."
    echo "Also ensure 'Proxy DNS when using SOCKS v5' is checked."
    echo "Or, with other browsers like Chrome you could use a browser plugin like foxyproxy to do the same thing as Firefox."
  else  # using MetalLB and public IP
    echo "OPTION 1: ACCESS APPLICATIONS WITH WEB BROWSER ONLY"
    echo "To access apps from browser only start ssh with application-level port forwarding:"
    echo "  ssh -i ~/.ssh/${KeyName}.pem ubuntu@${PublicIP} -D 127.0.0.1:12345"
    echo "Do not edit /etc/hosts on your local workstation."
    echo "Edit /etc/hosts on the EC2 instance. Sample /etc/host entries have already been added there."
    echo "Manually add more hostnames as needed."
    echo "The IPs to use come from the istio-system services of type LOADBALANCER EXTERNAL-IP that are created when Istio is deployed."
    echo "You must use Firefox browser with with manual SOCKs v5 proxy configuration to localhost with port 12345."
    echo "Also ensure 'Proxy DNS when using SOCKS v5' is checked."
    echo "Or, with other browsers like Chrome you could use a browser plugin like foxyproxy to do the same thing as Firefox."
    echo
    echo "OPTION 2: ACCESS APPLICATIONS WITH WEB BROWSER AND COMMAND LINE"
    echo "To access apps from browser and from the workstation command line start sshuttle in a separate terminal window."
    echo "  sshuttle --dns -vr ubuntu@${PublicIP} 172.20.1.0/24 --ssh-cmd 'ssh -i ~/.ssh/${KeyName}.pem'"
    echo "Edit your workstation /etc/hosts to add the LOADBALANCER EXTERNAL-IPs from the istio-system servcies with application hostnames."
    echo "Here is an example. You might have to change this depending on the number of gateways you configure for k8s cluster."
    echo "  # METALLB ISTIO INGRESS IPs"
    echo "  172.20.1.240 keycloak.bigbang.dev vault.bigbang.dev"
    echo "  172.20.1.241 sonarqube.bigbang.dev prometheus.bigbang.dev nexus.bigbang.dev gitlab.bigbang.dev"
  fi
elif [[ "$PRIVATE_IP" == true ]]  # not using MetalLB
then	# Not using MetalLB and using private IP
  echo "Start sshuttle in a separate terminal window:"
  echo "  sshuttle --dns -vr ubuntu@${PublicIP} 172.31.0.0/16 --ssh-cmd 'ssh -i ~/.ssh/${KeyName}.pem'"
  echo
  echo "To access apps from a browser edit your /etc/hosts to add the private IP of your EC2 instance with application hostnames. Example:"
  echo "  ${PrivateIP}	gitlab.bigbang.dev prometheus.bigbang.dev kibana.bigbang.dev"
  echo
else   # Not using MetalLB and using public IP. This is the default
  echo "To access apps from a browser edit your /etc/hosts to add the public IP of your EC2 instance with application hostnames."
  echo "Example:"
  echo "  ${PublicIP}	gitlab.bigbang.dev prometheus.bigbang.dev kibana.bigbang.dev"
  echo
fi
