#!/bin/bash

K3D_VERSION="5.7.3"
DEFAULT_K3S_TAG="v1.30.3-k3s1"

# get the current script dir
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

function run() {
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@${PublicIP} "$@"
}

function runwithexitcode() {
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@${PublicIP} "$@"
  exitcode=$?
  [ $exitcode -eq 0 ]
}

function runwithreturn() {
  echo $(ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@${PublicIP} "$@")
}

function getPrivateIP2() {
  echo `aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddresses[] | select(.Primary==false) | .PrivateIpAddress'`
}

function getDefaultAmi() {
  local partition
  local ubuntu_account_id
  local image_id
  # extract partition from the ARN
  partition=$(aws sts get-caller-identity --query 'Arn' --output text | awk -F ":" '{print $2}')
  # Select the correct AWS Account ID for Ubuntu Server AMI based on the partition
  if [[ "${partition}" == "aws-us-gov" ]]; then
      ubuntu_account_id="513442679011"
  elif [[ "${partition}" == "aws" ]]; then
      ubuntu_account_id="099720109477"
  else
      echo "Unrecognized AWS partition"
      exit 1
  fi
  # Filter on latest 22.04 jammy server
  image_id=$(aws ec2 describe-images \
    --owners ${ubuntu_account_id} \
    --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*' \
    --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
    --output text)

  if [ $? -ne 0 ] || [ "${image_id}" == "None" ]; then
      echo "Error getting AMI ID"
      exit 1
  fi
  echo "${image_id}"
}

#### Global variables - These allow the script to be run by non-bigbang devs easily - Update VPC_ID here or export environment variable for it if not default VPC
if [[ -z "${VPC_ID}" ]]; then
  VPC_ID="$(aws ec2 describe-vpcs --filters Name=is-default,Values=true | jq -j .Vpcs[0].VpcId)"
  if [[ -z "${VPC_ID}" ]]; then
    echo "AWS account has no default VPC - please provide VPC_ID"
    exit 1
  fi
fi

if [[ -n "${SUBNET_ID}" ]]; then
  if [[ "$(aws ec2 describe-subnets --subnet-id "${SUBNET_ID}" --filters "Name=vpc-id,Values=${VPC_ID}" | jq -j .Subnets[0])" == "null" ]]; then
    echo "SUBNET_ID ${SUBNET_ID} does not belong to VPC ${VPC_ID}"
    exit 1
  fi
else
  SUBNET_ID="$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" "Name=default-for-az,Values=true" | jq -j .Subnets[0].SubnetId)"
  if [[ "${SUBNET_ID}" == "null" ]]; then
    echo "VPC ${VPC_ID} has no default subnets - please provide SUBNET_ID"
    exit 1
  fi
fi

# If the user is using her own AMI, then respect that and do not update it.
APT_UPDATE="true"
if [[ $AMI_ID ]]; then
  APT_UPDATE="false"
else
  # default
  AMI_ID=$(getDefaultAmi)
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
ATTACH_SECONDARY_IP=${ATTACH_SECONDARY_IP:=false}

while [ -n "$1" ]; do # while loop starts

  case "$1" in

  -b) echo "-b option passed for big k3d cluster using M5 instance" 
      BIG_INSTANCE=true
  ;;

  -p) echo "-p option passed to create k3d cluster with private ip"
      if [[ "${ATTACH_SECONDARY_IP}" = false ]]; then
        PRIVATE_IP=true
      else
        echo "Disabling -p option because -a was specified."
      fi
  ;;

  -m) echo "-m option passed to install MetalLB"
      if [[ "${ATTACH_SECONDARY_IP}" = false ]]; then
        METAL_LB=true
      else
        echo "Disabling -m option because -a was specified."
      fi
  ;;

  -a) echo "-a option passed to create secondary public IP (-p and -m flags are skipped if set)"
      PRIVATE_IP=false
      METAL_LB=false
      ATTACH_SECONDARY_IP=true
  ;;

  -d) echo "-d option passed to destroy the AWS resources"
      AWSINSTANCEIDs=$( aws ec2 describe-instances \
        --output text \
        --query "Reservations[].Instances[].InstanceId" \
        --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=instance-state-name,Values=running" )
      # If instance exists then terminate it 
      if [[ $AWSINSTANCEIDs ]]; then 
        echo "aws instances being terminated: ${AWSINSTANCEIDs}"
        
        read -p "Are you sure you want to delete these instances (y/n)? " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          echo
          exit 1
        fi

        aws ec2 terminate-instances --instance-ids ${AWSINSTANCEIDs} &>/dev/null
        echo -n "Waiting for instance termination..."
        aws ec2 wait instance-terminated --instance-ids ${AWSINSTANCEIDs} &> /dev/null
        echo "done"
      else
        echo "You had no running instances."
      fi
      echo "SecurityGroup name to be deleted: ${SGname}"
      aws ec2 delete-security-group --group-name=${SGname} &> /dev/null
      echo "KeyPair to be deleted: ${KeyName}"
      aws ec2 delete-key-pair --key-name ${KeyName} &> /dev/null
      ALLOCATIONIDs=(`aws ec2 describe-addresses --output text --filter "Name=tag:Owner,Values=${AWSUSERNAME}" --query "Addresses[].AllocationId"`)
      for i in "${ALLOCATIONIDs[@]}"
      do
         echo -n "Releasing Elastic IP $i ..."
         aws ec2 release-address --allocation-id $i
         echo "done"
      done
      exit 0 
  ;;

  -h) echo "Usage:"
      echo "k3d-dev.sh -b -p -m -a -d -h"
      echo ""
      echo " -b   use BIG M5 instance. Default is m5a.4xlarge"
      echo " -p   use private IP for security group and k3d cluster"
      echo " -m   create k3d cluster with metalLB"
      echo " -a   attach secondary Public IP (overrides -p and -m flags)"
      echo " -d   destroy related AWS resources"
      echo " -w   install the weave CNI instead of the default flannel CNI"
      echo " -h   output help"
      exit 0
  ;;

  -w) echo "-w option passed to use Weave CNI" 
      USE_WEAVE=true
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
  if [[ $InstId ]]; then
    PublicIP=`aws ec2 describe-instances --output text --no-cli-pager --instance-id ${InstId} --query "Reservations[].Instances[].PublicIpAddress"`
    PrivateIP=`aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PrivateIpAddress'`
    echo "Existing cluster found running on instance ${InstId} on ${PublicIP} / ${PrivateIP}"
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
          SecondaryIP=`aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddresses[] | select(.Primary==false) | .Association.PublicIp'`
          PrivateIP2=$(getPrivateIP2)
          if [[ "${ATTACH_SECONDARY_IP}" == true && -z "${SecondaryIP}" ]]; then
            echo "Secondary IP didn't exist at the time of creation of the instance, so cannot attach one without re-creating it with the -a flag selected."
            exit 1
          fi
          run "k3d cluster delete"
          run "docker ps -aq | xargs docker stop | xargs docker rm"
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
          if [[ "${ATTACH_SECONDARY_IP}" == true ]]; then
            echo -n "Waiting for instance termination..."
            aws ec2 wait instance-terminated --instance-ids ${InstId} &> /dev/null
            echo "done"
          fi
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


  #### Cleaning up unused Elastic IPs
  ALLOCATIONIDs=(`aws ec2 describe-addresses --filter "Name=tag:Owner,Values=${AWSUSERNAME}" --query "Addresses[?AssociationId==null]" | jq -r '.[].AllocationId'`)
  for i in "${ALLOCATIONIDs[@]}"
  do
     echo -n "Releasing Elastic IP $i ..."
     aws ec2 release-address --allocation-id $i
     echo "done"
  done

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
  #### SecurityGroupId=$(aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} --query "SecurityGroups[0].GroupId" --output text)
  SecurityGroupId=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$SGname --query 'SecurityGroups[*].[GroupId]' --output text)
  echo done

  # Add name tag to security group
  aws ec2 create-tags --resources ${SecurityGroupId} --tags Key=Name,Value=${SGname} &> /dev/null


  # Add rule for IP based filtering
  WorkstationIP=`curl http://checkip.amazonaws.com/ 2> /dev/null`
  echo -n Checking if ${WorkstationIP} is authorized in security group ...
  #### aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} | grep ${WorkstationIP} > /dev/null || ipauth=missing
  aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$SGname | grep ${WorkstationIP} > /dev/null || ipauth=missing
  if [ "${ipauth}" == "missing" ]; then
    echo -e "missing\nAdding ${WorkstationIP} to security group ${SGname} ..."
    if [[ "$PRIVATE_IP" == true ]];
    then
      #### aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol tcp --port 22 --cidr ${WorkstationIP}/32
      #### aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol tcp --port 6443 --cidr ${WorkstationIP}/32
      aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-id ${SecurityGroupId} --protocol tcp --port 22 --cidr ${WorkstationIP}/32
      aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-id ${SecurityGroupId} --protocol tcp --port 6443 --cidr ${WorkstationIP}/32
    else  # all protocols to all ports is the default
      #### aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol all --cidr ${WorkstationIP}/32
      aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-id ${SecurityGroupId} --protocol all --cidr ${WorkstationIP}/32
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

  if [[ "${ATTACH_SECONDARY_IP}" == true ]]; then
    # If we are using a secondary IP, we don't want to assign public IPs at launch time. Instead, the script will attach both public IPs after the instance is launched.
    additional_create_instance_options="--no-associate-public-ip-address --secondary-private-ip-address-count 1"
  else
    additional_create_instance_options="--associate-public-ip-address"
  fi

  InstId=`aws ec2 run-instances \
    --output json --no-paginate \
    --count 1 --image-id "${ImageId}" \
    --instance-type "${InstanceType}" \
    --subnet-id "${SUBNET_ID}" \
    --key-name "${KeyName}" \
    --security-group-ids "${SecurityGroupId}" \
    --instance-initiated-shutdown-behavior "terminate" \
    --user-data file://$HOME/aws/userdata.txt \
    --block-device-mappings file://$HOME/aws/device_mappings.json \
    --instance-market-options file://$HOME/aws/spot_options.json \
    ${additional_create_instance_options} \
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
  echo "Almost there, 15 seconds to go..."
  sleep 15

  ## IP Address Allocation and Attachment
  CURRENT_EPOCH=`date +'%s'`

  # Get the private IP address of our instance
  PrivateIP=`aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PrivateIpAddress'`

  # Use Elastic IPs if a Secondary IP is required, instead of the auto assigned one.
  if [[ "${ATTACH_SECONDARY_IP}" == false ]]; then
    PublicIP=`aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PublicIpAddress'`
  else
    echo "Checking to see if an Elastic IP is already allocated and not attached..."
    PublicIP=`aws ec2 describe-addresses --filter "Name=tag:Name,Values=${AWSUSERNAME}-EIP1" --query 'Addresses[?AssociationId==null]' | jq -r '.[0].PublicIp // ""'`
    if [[ -z "${PublicIP}" ]]; then
      echo "Allocating a new/another primary elastic IP..."
      PublicIP=`aws ec2 allocate-address --output json --no-cli-pager --tag-specifications="ResourceType=elastic-ip,Tags=[{Key=Name,Value=${AWSUSERNAME}-EIP1},{Key=Owner,Value=${AWSUSERNAME}}]" | jq -r '.PublicIp'`
    else
      echo "Previously allocated primary Elastic IP ${PublicIP} found."
    fi

    echo -n "Associating IP ${PublicIP} address to instance ${InstId} ..."
    EIP1_ASSOCIATION_ID=`aws ec2 associate-address --output json --no-cli-pager --instance-id ${InstId} --private-ip ${PrivateIP} --public-ip $PublicIP | jq -r '.AssociationId'`
    echo "${EIP1_ASSOCIATION_ID}"
    EIP1_ID=`aws ec2 describe-addresses --public-ips ${PublicIP} | jq -r '.Addresses[].AllocationId'`
    aws ec2 create-tags --resources ${EIP1_ID} --tags Key="lastused",Value="${CURRENT_EPOCH}"

    PrivateIP2=$(getPrivateIP2)
    echo "Checking to see if a Secondary Elastic IP is already allocated and not attached..."
    SecondaryIP=`aws ec2 describe-addresses --filter "Name=tag:Name,Values=${AWSUSERNAME}-EIP2" --query 'Addresses[?AssociationId==null]' | jq -r '.[0].PublicIp // ""'`
    if [[ -z "${SecondaryIP}" ]]; then
      echo "Allocating a new/another secondary elastic IP..."
      SecondaryIP=`aws ec2 allocate-address --output json --no-cli-pager --tag-specifications="ResourceType=elastic-ip,Tags=[{Key=Name,Value=${AWSUSERNAME}-EIP2},{Key=Owner,Value=${AWSUSERNAME}}]" | jq -r '.PublicIp'`
    else
      echo "Previously allocated secondary Elastic IP ${SecondaryIP} found."
    fi
    echo -n "Associating Secondary IP ${SecondaryIP} address to instance ${InstId}..."
    EIP2_ASSOCIATION_ID=`aws ec2 associate-address --output json --no-cli-pager --instance-id ${InstId} --private-ip ${PrivateIP2} --public-ip $SecondaryIP | jq -r '.AssociationId'`
    echo "${EIP2_ASSOCIATION_ID}"
    EIP2_ID=`aws ec2 describe-addresses --public-ips ${SecondaryIP} | jq -r '.Addresses[].AllocationId'`
    aws ec2 create-tags --resources ${EIP2_ID} --tags Key="lastused",Value="${CURRENT_EPOCH}"
    echo "Secondary public IP is ${SecondaryIP}"
  fi

  echo
  echo "Instance ${InstId} is ready!"
  echo "Instance Public IP is ${PublicIP}"
  echo "Instance Private IP is ${PrivateIP}"
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

  ##### Configure Instance
  ## TODO: replace these individual commands with userdata when the spot instance is created?
  echo
  echo
  echo "starting instance config"

  echo "Instance will automatically terminate 8 hours from now unless you alter the root crontab"
  run "sudo bash -c 'echo \"\$(date -u -d \"+8 hours\" +\"%M %H\") * * * /usr/sbin/shutdown -h now\" | crontab -'"
  echo

  if [[ $APT_UPDATE = "true" ]]; then
    echo
    echo "updating packages"
    run "sudo apt-get update && sudo apt-get upgrade -y"
  fi

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
fi

# install k3d on instance
echo "Installing k3d on instance"
run "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v${K3D_VERSION} bash"
echo
echo "k3d version"
run "k3d version"
echo

echo "creating k3d cluster"

# Shared k3d settings across all options
# 1 server, 3 agents
k3d_command="export K3D_FIX_MOUNTS=1; k3d cluster create --servers 1 --agents 3 --verbose"
# Volumes to support Twistlock defenders
k3d_command+=" -v /etc:/etc@server:*\;agent:* -v /dev/log:/dev/log@server:*\;agent:* -v /run/systemd/private:/run/systemd/private@server:*\;agent:*"
# Disable traefik and metrics-server
k3d_command+=" --k3s-arg \"--disable=traefik@server:0\" --k3s-arg \"--disable=metrics-server@server:0\""

# Port mappings to support Istio ingress + API access
if [[ -z "${PrivateIP2}" ]]; then
  k3d_command+=" --port ${PrivateIP}:80:80@loadbalancer --port ${PrivateIP}:443:443@loadbalancer --api-port 6443"
fi

# Selecting K8S version through the use of a K3S image tag
K3S_IMAGE_TAG=${K3S_IMAGE_TAG:="${DEFAULT_K3S_TAG}"}
if [[ $K3S_IMAGE_TAG ]]; then
  echo "Using custom K3S image tag $K3S_IMAGE_TAG..."
  k3d_command+=" --image docker.io/rancher/k3s:$K3S_IMAGE_TAG"
fi

# create docker network for k3d cluster
echo "creating docker network for k3d cluster"
run "docker network remove k3d-network"
run "docker network create k3d-network --driver=bridge --subnet=172.20.0.0/16 --gateway 172.20.0.1"
k3d_command+=" --network k3d-network"

# Add MetalLB specific k3d config
if [[ "$METAL_LB" == true || "$ATTACH_SECONDARY_IP" == true ]]; then
  k3d_command+=" --k3s-arg \"--disable=servicelb@server:0\""
fi

# Add Public/Private IP specific k3d config
if [[ "$PRIVATE_IP" == true ]]; then
  echo "using private ip for k3d"
  k3d_command+=" --k3s-arg \"--tls-san=${PrivateIP}@server:0\""
else
  echo "using public ip for k3d"
  k3d_command+=" --k3s-arg \"--tls-san=${PublicIP}@server:0\""
fi

# use weave instead of flannel -- helps with large installs
# we match the 172.x subnets used by CI for consistency
if [[ "$USE_WEAVE" == true ]]; then

  run "if [[ ! -f /opt/cni/bin/loopback ]]; then sudo mkdir -p /opt/cni/bin && sudo curl -s -L https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz  | sudo tar xvz -C /opt/cni/bin; fi"

  scp -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${SCRIPT_DIR}/weave/* ubuntu@${PublicIP}:/tmp/

  # network settings  
  k3d_command+=" --k3s-arg \"--flannel-backend=none@server:*\""
  k3d_command+=" --k3s-arg \"--disable-network-policy@server:*\""
  k3d_command+=" --k3s-arg \"--cluster-cidr=172.21.0.0/16@server:*\""
  k3d_command+=" --k3s-arg \"--service-cidr=172.20.0.0/16@server:*\""
  k3d_command+=" --k3s-arg \"--cluster-dns=172.20.0.10@server:*\""

  # volume mounts
  k3d_command+=" --volume \"/tmp/weave.yaml:/var/lib/rancher/k3s/server/manifests/weave.yaml@server:*\""
  k3d_command+=" --volume /tmp/machine-id-server-0:/etc/machine-id@server:0"
  k3d_command+=" --volume /tmp/machine-id-agent-0:/etc/machine-id@agent:0"
  k3d_command+=" --volume /tmp/machine-id-agent-1:/etc/machine-id@agent:1"
  k3d_command+=" --volume /tmp/machine-id-agent-2:/etc/machine-id@agent:2"
  k3d_command+=" --volume /opt/cni/bin:/opt/cni/bin@all:*"
fi

# Create k3d cluster
echo "Creating k3d cluster with command: ${k3d_command}"
run "${k3d_command}"

# install kubectl
echo Installing kubectl based on k8s version...
K3S_IMAGE_TAG=${K3S_IMAGE_TAG:="${DEFAULT_K3S_TAG}"}
if [[ $K3S_IMAGE_TAG ]]; then
  KUBECTL_VERSION=$(echo $K3S_IMAGE_TAG | cut -d'-' -f1)
  echo "Using specified kubectl version $KUBECTL_VERSION based on k3s image tag."
else
  KUBECTL_VERSION=$(runwithreturn "k3d version -o json" | jq -r '.k3s' | cut -d'-' -f1)
  echo "Using k3d default k8s version $KUBECTL_VERSION."
fi
KUBECTL_CHECKSUM=`curl -sL https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256`
run "curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
runwithexitcode "echo ${KUBECTL_CHECKSUM}  kubectl | sha256sum --check" && echo "Good checksum" || { echo "Bad checksum" ; exit 1; }
run 'sudo mv /home/ubuntu/kubectl /usr/local/bin/'
run 'sudo chmod +x /usr/local/bin/kubectl'

run "kubectl config use-context k3d-k3s-default"
run "kubectl cluster-info && kubectl get nodes"

echo "copying kubeconfig to workstation..."
mkdir -p ~/.kube
scp -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@${PublicIP}:/home/ubuntu/.kube/config ~/.kube/${AWSUSERNAME}-dev-config
if [[ "$PRIVATE_IP" == true ]]; then
  $sed_gsed -i "s/0\.0\.0\.0/${PrivateIP}/g" ~/.kube/${AWSUSERNAME}-dev-config
else  # default is to use public ip
  $sed_gsed -i "s/0\.0\.0\.0/${PublicIP}/g" ~/.kube/${AWSUSERNAME}-dev-config
fi

# Handle MetalLB cluster resource creation
if [[ "${METAL_LB}" == true || "${ATTACH_SECONDARY_IP}" == true ]]; then
  echo "Installing MetalLB..."

  until [[ ${REGISTRY_USERNAME} ]]; do
    read -p "Please enter your Registry1 username: " REGISTRY_USERNAME
  done
  until [[ ${REGISTRY_PASSWORD} ]]; do
    read -s -p "Please enter your Registry1 password: " REGISTRY_PASSWORD
  done
  run "kubectl create namespace metallb-system"
  run "kubectl create secret docker-registry registry1 \
    --docker-server=registry1.dso.mil \
    --docker-username=${REGISTRY_USERNAME} \
    --docker-password=${REGISTRY_PASSWORD} \
    -n metallb-system"

  run "mkdir /tmp/metallb"
  scp -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${SCRIPT_DIR}/metallb/* ubuntu@${PublicIP}:/tmp/metallb
  run "kubectl apply -k /tmp/metallb"

  # Wait for controller to be live so that validating webhooks function when we apply the config
  echo "Waiting for MetalLB controller..."
  run "kubectl wait --for=condition=available --timeout 120s -n metallb-system deployment controller"
  echo "MetalLB is installed."

  if [[ "$METAL_LB" == true ]]; then
    echo "Building MetalLB configuration for -m mode."
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
  elif [[ "$ATTACH_SECONDARY_IP" == true ]]; then
    echo "Building MetalLB configuration for -a mode."
    run <<ENDSSH
#run this command on remote
cat <<EOF > metallb-config.yaml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: primary
  namespace: metallb-system
  labels:
    privateIp: "$PrivateIP"
    publicIp: "$PublicIP"
spec:
  addresses:
  - "172.20.1.241/32"
  serviceAllocation:
    priority: 100
    namespaces:
      - istio-system
    serviceSelectors:
      - matchExpressions:
          - {key: app, operator: In, values: [public-ingressgateway]}
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: secondary
  namespace: metallb-system
  labels:
    privateIp: "$PrivateIP2"
    publicIp: "$SecondaryIP"
spec:
  addresses:
  - "172.20.1.240/32"
  serviceAllocation:
    priority: 100
    namespaces:
      - istio-system
    serviceSelectors:
      - matchExpressions:
          - {key: app, operator: In, values: [passthrough-ingressgateway]}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: primary
  namespace: metallb-system
spec:
  ipAddressPools:
  - primary
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: secondary
  namespace: metallb-system
spec:
  ipAddressPools:
  - secondary
EOF
ENDSSH

    run <<ENDSSH
cat <<EOF > primaryProxy.yaml
ports:
  443.tcp:
    - 172.20.1.241
settings:
  workerConnections: 1024
EOF
ENDSSH

    run <<ENDSSH
cat <<EOF > secondaryProxy.yaml
ports:
  443.tcp:
    - 172.20.1.240
settings:
  workerConnections: 1024
EOF
ENDSSH

    run "docker run -d --name=primaryProxy --network=k3d-network -p $PrivateIP:443:443  -v /home/ubuntu/primaryProxy.yaml:/etc/confd/values.yaml ghcr.io/k3d-io/k3d-proxy:$K3D_VERSION"
    run "docker run -d --name=secondaryProxy --network=k3d-network -p $PrivateIP2:443:443 -v /home/ubuntu//secondaryProxy.yaml:/etc/confd/values.yaml ghcr.io/k3d-io/k3d-proxy:$K3D_VERSION"
  fi

  run "kubectl create -f metallb-config.yaml"
fi

if [[ "$METAL_LB" == true ]]; then
  run <<- 'ENDSSH'
  # run this command on remote
  # fix /etc/hosts for new cluster
  sudo sed -i '/dev.bigbang.mil/d' /etc/hosts
  sudo bash -c "echo '## begin dev.bigbang.mil section (METAL_LB)' >> /etc/hosts"
  sudo bash -c "echo 172.20.1.240  keycloak.dev.bigbang.mil vault.dev.bigbang.mil >> /etc/hosts"
  sudo bash -c "echo 172.20.1.241 anchore-api.dev.bigbang.mil anchore.dev.bigbang.mil argocd.dev.bigbang.mil gitlab.dev.bigbang.mil registry.dev.bigbang.mil tracing.dev.bigbang.mil kiali.dev.bigbang.mil kibana.dev.bigbang.mil chat.dev.bigbang.mil minio.dev.bigbang.mil minio-api.dev.bigbang.mil alertmanager.dev.bigbang.mil grafana.dev.bigbang.mil prometheus.dev.bigbang.mil nexus.dev.bigbang.mil sonarqube.dev.bigbang.mil tempo.dev.bigbang.mil twistlock.dev.bigbang.mil >> /etc/hosts"
  sudo bash -c "echo '## end dev.bigbang.mil section' >> /etc/hosts"
  # run kubectl to add keycloak and vault's hostname/IP to the configmap for coredns, restart coredns
  kubectl get configmap -n kube-system coredns -o yaml | sed '/^    172.20.0.1 host.k3d.internal$/a\ \ \ \ 172.20.1.240 keycloak.dev.bigbang.mil vault.dev.bigbang.mil' | kubectl apply -f -
  kubectl delete pod -n kube-system -l k8s-app=kube-dns
	ENDSSH
elif [[ "$ATTACH_SECONDARY_IP" == true ]]; then
  run <<ENDSSH
    # run this command on remote
    # fix /etc/hosts for new cluster
    sudo sed -i '/dev.bigbang.mil/d' /etc/hosts
    sudo bash -c "echo '## begin dev.bigbang.mil section (ATTACH_SECONDARY_IP)' >> /etc/hosts"
    sudo bash -c "echo $PrivateIP2  keycloak.dev.bigbang.mil vault.dev.bigbang.mil >> /etc/hosts"
    sudo bash -c "echo $PrivateIP anchore-api.dev.bigbang.mil anchore.dev.bigbang.mil argocd.dev.bigbang.mil gitlab.dev.bigbang.mil registry.dev.bigbang.mil tracing.dev.bigbang.mil kiali.dev.bigbang.mil kibana.dev.bigbang.mil chat.dev.bigbang.mil minio.dev.bigbang.mil minio-api.dev.bigbang.mil alertmanager.dev.bigbang.mil grafana.dev.bigbang.mil prometheus.dev.bigbang.mil nexus.dev.bigbang.mil sonarqube.dev.bigbang.mil tempo.dev.bigbang.mil twistlock.dev.bigbang.mil >> /etc/hosts"
    sudo bash -c "echo '## end dev.bigbang.mil section' >> /etc/hosts"
    # run kubectl to add keycloak and vault's hostname/IP to the configmap for coredns, restart coredns
    kubectl get configmap -n kube-system coredns -o yaml | sed '/^    .* host.k3d.internal$/a\ \ \ \ $PrivateIP2 keycloak.dev.bigbang.mil vault.dev.bigbang.mil' | kubectl apply -f -
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

if [[ "$METAL_LB" == true ]]; then # using MetalLB
  if [[ "$PRIVATE_IP" == true ]]; then # using MetalLB and private IP
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
    echo "Edit your workstation /etc/hosts to add the LOADBALANCER EXTERNAL-IPs from the istio-system services with application hostnames."
    echo "Here is an example. You might have to change this depending on the number of gateways you configure for k8s cluster."
    echo "  # METALLB ISTIO INGRESS IPs"
    echo "  172.20.1.240 keycloak.dev.bigbang.mil vault.dev.bigbang.mil"
    echo "  172.20.1.241 sonarqube.dev.bigbang.mil prometheus.dev.bigbang.mil nexus.dev.bigbang.mil gitlab.dev.bigbang.mil"
  fi
elif [[ "$PRIVATE_IP" == true ]]; then  # not using MetalLB
	# Not using MetalLB and using private IP
  echo "Start sshuttle in a separate terminal window:"
  echo "  sshuttle --dns -vr ubuntu@${PublicIP} 172.31.0.0/16 --ssh-cmd 'ssh -i ~/.ssh/${KeyName}.pem'"
  echo
  echo "To access apps from a browser edit your /etc/hosts to add the private IP of your EC2 instance with application hostnames. Example:"
  echo "  ${PrivateIP}  gitlab.dev.bigbang.mil prometheus.dev.bigbang.mil kibana.dev.bigbang.mil"
  echo 
else   # Not using MetalLB and using public IP. This is the default
  echo "To access apps from a browser edit your /etc/hosts to add the public IP of your EC2 instance with application hostnames."
  echo "Example:"
  echo "  ${PublicIP} gitlab.dev.bigbang.mil prometheus.dev.bigbang.mil kibana.dev.bigbang.mil"
  echo

  if [[ $SecondaryIP ]]; then
    echo "A secondary IP is available for use if you wish to have a passthrough ingress for Istio along with a public Ingress Gateway, this maybe useful for Keycloak x509 mTLS authentication."
    echo "  $SecondaryIP  keycloak.dev.bigbang.mil"
  fi
fi
