#!/bin/bash

#### Global variables

### Initialized globals

K3D_VERSION="5.7.3"
DEFAULT_K3S_TAG="v1.31.4-k3s1"
CLOUDPROVIDER="aws"
SSHUSER=ubuntu
action=create_instances
ATTACH_SECONDARY_IP=${ATTACH_SECONDARY_IP:=false}
BIG_INSTANCE=false
METAL_LB=false
PRIVATE_IP=false
PROJECTTAG=default
RESET_K3D=false
USE_WEAVE=false
TERMINATE_INSTANCE=true
QUIET=false
TMPDIR=$(mktemp -d)

### Uninitialized globals

# The quickstart instructions have the user set these. Not all users
# will have these set. But this will prevent (some) users from getting
# a prompt when they go to install metallb.
REGISTRY_USERNAME=${REGISTRY1_USERNAME:-}
REGISTRY_PASSWORD=${REGISTRY1_TOKEN:-}
CLOUD_RECREATE_INSTANCE=false
INIT_SCRIPT=""
RUN_BATCH_FILE=""
CURRENT_EPOCH=0
KUBECONFIG=""
KUBECTL_CHECKSUM=""
KUBECTL_VERSION=""
PrivateIP=""
PublicIP=""
SSHKEY=""

### AWS Cloud provider globals
AMI_ID=${AMI_ID:-""}
VPC_ID=${VPC_ID:-""}
AWSUSERNAME=""
EIP1_ASSOCIATION_ID=""
EIP1_ID=""
EIP2_ASSOCIATION_ID=""
EIP2_ID=""
EXISTING_VPC=""
SUBNET_ID=""
SecondaryIP=""

# get the current script dir
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
trap "rm -fr ${TMPDIR}" EXIT

function process_arguments {
  while [ -n "$1" ]; do # while loop starts

    case "$1" in

    -t)
      echo "-t option passed to use additional tags on instance"
      shift
      PROJECTTAG=$1
      ;;

    -b)
      echo "-b option passed for big k3d cluster using M5 instance"
      BIG_INSTANCE=true
      ;;

    -p)
      echo "-p option passed to create k3d cluster with private ip"
      if [[ "${ATTACH_SECONDARY_IP}" = false ]]; then
        PRIVATE_IP=true
      else
        echo "Disabling -p option because -a was specified."
      fi
      ;;

    -m)
      echo "-m option passed to install MetalLB"
      if [[ "${ATTACH_SECONDARY_IP}" = false ]]; then
        METAL_LB=true
      else
        echo "Disabling -m option because -a was specified."
      fi
      ;;

    -a)
      echo "-a option passed to create secondary public IP (-p and -m flags are skipped if set)"
      PRIVATE_IP=false
      METAL_LB=false
      ATTACH_SECONDARY_IP=true
      ;;

    -d)
      echo "-d option passed to destroy the AWS resources"
      action=destroy_instances
      ;;

    -i)
      echo "-i option passed to send init script to k3d instance"
      shift
      INIT_SCRIPT=$1
      ;;

    -H)
      echo "-H option passed to use existing system public IP"
      shift
      PublicIP=$1
      ;;

    -P)
      echo "-P option passed to use existing system private IP"
      shift
      PrivateIP=$1
      ;;

    -U)
      echo "-U option passed to provide username for connecting to existing system"
      shift
      SSHUSER=$1
      ;;

    -k)
      echo "-k option passed to provide SSH key for connecting to existing system"
      shift
      SSHKEY=$1
      ;;

    -c)
      echo "-c option passed to specify cloud provider"
      shift
      CLOUDPROVIDER=$1
      ;;

    -T)
      echo "-T option passed to prevent instance termination"
      TERMINATE_INSTANCE=false
      ;;
    -q)
      QUIET=true
      ;;

    -h)
      echo "Usage:"
      echo "k3d-dev.sh [options]"
      echo ""
      echo " -c CLOUD             Use the given CLOUD for cloud infra provisioning [aws]"
      echo
      echo "========= The following options ONLY APPLY with [-c aws] =================="
      echo
      echo " -b   use BIG M5 instance. Default is m5a.4xlarge"
      echo " -a   attach secondary Public IP (overrides -p and -m flags)"
      echo " -d   destroy related AWS resources"
      echo " -R   recreate the EC2 instance (shortcut for -d and running again with same flags)"
      echo " -r   Report on all instances owned by your user"
      echo " -u   Update security group for instances"
      echo
      echo "========= These options apply regardless of cloud provider ================"
      echo
      echo " -K   recreate the k3d cluster on the host"
      echo " -m   create k3d cluster with metalLB load balancer"
      echo " -p   use private IP for security group and k3d cluster"
      echo " -t   Set the project tag on the instance (for managing multiple instances)"
      echo " -w   install the weave CNI instead of the default flannel CNI"
      echo " -i /path/to/script   initialization script to pass to instance before configuring it"
      echo " -U username          username to use when connecting to existing system in -P"
      echo " -T   Don't terminate the instance after 8 hours"
      echo " -q   suppress the final completion message"
      echo
      echo "========= These options override -c and use your own infrastructure ======="
      echo
      echo " -H xxx.xxx.xxx.xxx   Public IP address of existing system to configure"
      echo " -P xxx.xxx.xxx.xxx   private IP address of existing system to configure (if not provided and -H is set, the value of -H is assumed)"
      echo " -k /path/to/key/file SSH key to use when connecting to cluster instance"
      echo
      echo " -h   output help"
      exit 0
      ;;
    -K)
      RESET_K3D=true
      ;;
    -R)
      CLOUD_RECREATE_INSTANCE=true
      ;;
    -u)
      action=update_instances
      ;;

    -r)
      action=report_instances
      ;;

    -w)
      echo "-w option passed to use Weave CNI"
      USE_WEAVE=true
      ;;

    *) echo "Option $1 not recognized" ;; # In case a non-existent option is submitted

    esac
    shift
  done

  # Command argument post-processing
  if [[ "$PRIVATE_IP" == "true" ]] && [[ "$PublicIP" != "" ]] && [[ "$PrivateIP" == "" ]]; then
    echo "When providing -p and -H you MUST provide -P (private IP address to use)." >&2
    exit 1
  fi

  if [[ "${PublicIP}" != "" ]] && [[ "$PrivateIP" == "" ]]; then
    PrivateIP=$PublicIP
  fi

}

function check_missing_tools {
  # check for tools
  tooldependencies=(jq sed ssh ssh-keygen scp kubectl tr base64 $@)
  for tooldependency in "${tooldependencies[@]}"; do
    command -v $tooldependency >/dev/null 2>&1 || {
      echo >&2 " $tooldependency is not installed."
      missingtool=1
    }
  done
  sed_gsed="sed"
  # verify sed version if mac
  # alias prohibited, symlinks permitted
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
}

function cloud_aws_toolnames {
  echo aws
}

function cloud_aws_configure {
  # getting AWS user name
  AWSUSERNAME=$(aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/')

  SGname="${AWSUSERNAME}-dev-${PROJECTTAG}"
  KeyName="${AWSUSERNAME}-dev-${PROJECTTAG}"
  SSHKEY=~/.ssh/${KeyName}.pem

  # check for aws username environment variable. If not found then terminate script
  if [[ -z "${AWSUSERNAME}" ]]; then
    echo "You must configure your AWS credentials. Your AWS user name is used to name resources in AWS. Example:"
    echo "   aws configure"
    exit 1
  else
    echo "AWS User Name: ${AWSUSERNAME}"
  fi

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
}

function report_instances {
  if [[ "${CLOUDPROVIDER}" == "" ]]; then
    echo "Cannot report instances, no cloud provider set"
    exit 1
  fi
  cloud_${CLOUDPROVIDER}_report_instances
}

function cloud_aws_report_instances {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,SecurityGroups[0].GroupId,Tags[?Key==`Project`].Value | [0]]' \
    --output text
}

function set_kubeconfig {
  if [[ "$PublicIP" != "" ]]; then
    KUBECONFIG=${PublicIP}-dev-${PROJECTTAG}-config
  elif [[ "${AWSUSERNAME}" != "" ]]; then
    KUBECONFIG=${AWSUSERNAME}-dev-${PROJECTTAG}-config
  fi
}

function run_batch_new() {
  if [[ "$RUN_BATCH_FILE" != "" ]]; then
    echo "Can't manage more than one run batch at once" >&2
    exit 1
  fi
  RUN_BATCH_FILE=$(mktemp k3d_dev_run_batchXXX)
  echo '#!/bin/bash' >> ${RUN_BATCH_FILE}
  echo 'set -xue' >> ${RUN_BATCH_FILE}
}

function run_batch_add() {
  if [[ "$RUN_BATCH_FILE" == "" ]]; then
    echo "No run batch configured" >&2
    exit 1
  fi
  echo "$@" >> ${RUN_BATCH_FILE}
}

function run_batch_execute() {
  if [[ "$RUN_BATCH_FILE" == "" ]]; then
    echo "No run batch configured" >&2
    exit 1
  fi
  batch_basename=$(basename ${RUN_BATCH_FILE})
  cat ${RUN_BATCH_FILE} | run "sudo cat > /tmp/${batch_basename}"
  $(k3dsshcmd) -t "bash /tmp/${batch_basename}"
  if [[ $? -ne 0 ]]; then
    echo "Batch file /tmp/${batch_basename} failed on target system." >&2
    echo "You can debug it by logging into the system:" >&2
    echo
    k3dsshcmd >&2
    rm -f ${RUN_BATCH_FILE}
    exit 1
  fi
  rm -f ${RUN_BATCH_FILE}
  RUN_BATCH_FILE=""
}

function k3dsshcmd() {
  echo "ssh -i ${SSHKEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${SSHUSER}@${PublicIP}"
}

function run() {
  $(k3dsshcmd) "$@"
}

function runwithexitcode() {
  $(k3dsshcmd) "$@"
  return $?
}

function runwithreturn() {
  $(k3sshcmd) "$@"
}

function getPrivateIP2() {
  if [[ "$PrivateIP2" == "" ]]; then
    export PrivateIP2=$(aws ec2 describe-instances --output json --no-cli-pager --instance-ids "${InstId}" | jq -r '.Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddresses[] | select(.Primary==false) | .PrivateIpAddress')
  fi
  echo $PrivateIP2
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

function update_ec2_security_group {
  # Look up the security group created to get the ID
  echo -n Retrieving ID for security group ${SGname} ...
  #### SecurityGroupId=$(aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} --query "SecurityGroups[0].GroupId" --output text)
  SecurityGroupId=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$SGname --query 'SecurityGroups[*].[GroupId]' --output text)
  echo done

  # Add name tag to security group
  aws ec2 create-tags --resources ${SecurityGroupId} --tags Key=Name,Value=${SGname} &>/dev/null
  aws ec2 create-tags --resources ${SecurityGroupId} --tags Key=Project,Value=${PROJECTTAG} &>/dev/null

  # Add rule for IP based filtering
  WorkstationIP=$(curl http://checkip.amazonaws.com/ 2>/dev/null)
  echo -n Checking if ${WorkstationIP} is authorized in security group ...
  #### aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} | grep ${WorkstationIP} > /dev/null || ipauth=missing
  aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$SGname | grep ${WorkstationIP} >/dev/null || ipauth=missing
  if [ "${ipauth}" == "missing" ]; then
    echo -e "missing\nAdding ${WorkstationIP} to security group ${SGname} ..."
    if [[ "$PRIVATE_IP" == true ]]; then
      #### aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol tcp --port 22 --cidr ${WorkstationIP}/32
      #### aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol tcp --port 6443 --cidr ${WorkstationIP}/32
      aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-id ${SecurityGroupId} --protocol tcp --port 22 --cidr ${WorkstationIP}/32
      aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-id ${SecurityGroupId} --protocol tcp --port 6443 --cidr ${WorkstationIP}/32
    else # all protocols to all ports is the default
      #### aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-name ${SGname} --protocol all --cidr ${WorkstationIP}/32
      aws ec2 authorize-security-group-ingress --output json --no-cli-pager --group-id ${SecurityGroupId} --protocol all --cidr ${WorkstationIP}/32
    fi
    echo done
  else
    echo found
  fi
}

function destroy_instances {
  if [[ "$PublicIP" != "" ]] && [[ "${CLOUD_RECREATE_INSTANCE}" != "true" ]]; then
    echo "Public IP of instance has been provided; assuming instance was not provisioned by me."
    echo "Nothing to do."
    exit 1
  fi

  AWSINSTANCEIDs=$(aws ec2 describe-instances \
    --output text \
    --query "Reservations[].Instances[].InstanceId" \
    --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=tag:Project,Values=${PROJECTTAG}" "Name=instance-state-name,Values=running")
  # If instance exists then terminate it
  if [[ $AWSINSTANCEIDs ]]; then
    echo "aws instances being terminated: ${AWSINSTANCEIDs}"

    # Don't prompt the user if they already told us to do it
    if [[ "${CLOUD_RECREATE_INSTANCE}" != "true" ]]; then
      read -p "Are you sure you want to delete these instances (y/n)? " -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo
        exit 1
      fi 
    fi

    aws ec2 terminate-instances --instance-ids ${AWSINSTANCEIDs} &>/dev/null
    echo -n "Waiting for instance termination..."
    aws ec2 wait instance-terminated --instance-ids ${AWSINSTANCEIDs} &>/dev/null
    echo "done"
  else
    echo "You had no running instances."
  fi
  echo "SecurityGroup name to be deleted: ${SGname}"
  aws ec2 delete-security-group --group-name=${SGname} &>/dev/null
  echo "KeyPair to be deleted: ${KeyName}"
  aws ec2 delete-key-pair --key-name ${KeyName} &>/dev/null
  ALLOCATIONIDs=($(aws ec2 describe-addresses --output text --filters "Name=tag:Owner,Values=${AWSUSERNAME}" "Name=tag:Project,Values=${PROJECTTAG}" --query "Addresses[].AllocationId"))
  for i in "${ALLOCATIONIDs[@]}"; do
    echo -n "Releasing Elastic IP $i ..."
    aws ec2 release-address --allocation-id $i
    echo "done"
  done
}

function update_instances {
  update_ec2_security_group
}

function install_docker {
  echo "installing docker"
  # install dependencies
  run_batch_new
  run_batch_add "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release gnupg-agent software-properties-common"
  # Add the Docker repository, we are installing from Docker and not the Ubuntu APT repo.
  run_batch_add 'sudo mkdir -m 0755 -p /etc/apt/keyrings'
  # gpg won't overwrite the file if we're rebuilding the cluster, we have to clear it
  run_batch_add 'sudo rm -f /etc/apt/keyrings/docker.gpg'
  run_batch_add 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --dearmor -o /etc/apt/keyrings/docker.gpg'
  run_batch_add 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
  run_batch_add "sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  # Add your base user to the Docker group so that you do not need sudo to run docker commands
  run_batch_add "sudo usermod -aG docker ubuntu"
  run_batch_execute
}

function install_k3d {
  # install k3d on instance
  echo "Installing k3d on instance"
  # Shared k3d settings across all options
  # 1 server, 3 agents
  k3d_command="export K3D_FIX_MOUNTS=1; k3d cluster create --servers 1 --agents 3 --verbose"
  # Volumes to support Twistlock defenders
  k3d_command+=" -v /etc:/etc@server:*\;agent:* -v /dev/log:/dev/log@server:*\;agent:* -v /run/systemd/private:/run/systemd/private@server:*\;agent:*"
  # Disable traefik and metrics-server
  k3d_command+=" --k3s-arg \"--disable=traefik@server:0\" --k3s-arg \"--disable=metrics-server@server:0\""

  # Port mappings to support Istio ingress + API access
  if [[ -z "$(getPrivateIP2)" ]]; then
    k3d_command+=" --port ${PrivateIP}:80:80@loadbalancer --port ${PrivateIP}:443:443@loadbalancer --api-port 6443"
  fi

  # Selecting K8S version through the use of a K3S image tag
  K3S_IMAGE_TAG=${K3S_IMAGE_TAG:="${DEFAULT_K3S_TAG}"}
  if [[ $K3S_IMAGE_TAG ]]; then
    echo "Using custom K3S image tag $K3S_IMAGE_TAG..."
    k3d_command+=" --image docker.io/rancher/k3s:$K3S_IMAGE_TAG"
  fi
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
    scp -i ${SSHKEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${SCRIPT_DIR}/weave/* ${SSHUSER}@${PublicIP}:/tmp/
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

  run_batch_new
  if [[ $RESET_K3D == "true" ]]; then
    # We may be recreating k3d on an existing cluster, so clean house first
    run_batch_add "k3d cluster delete --all"
    run_batch_add "docker ps -aq | xargs docker stop || true"
    run_batch_add "docker ps -aq | xargs docker rm -f || true"
    run_batch_add "docker system prune -a -f --volumes"
    run_batch_add "docker network remove k3d-network || true"
    run_batch_add "sudo systemctl restart docker"
  fi
  run_batch_add "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v${K3D_VERSION} bash"
  run_batch_add "k3d version"
  run_batch_add "docker network create k3d-network --driver=bridge --subnet=172.20.0.0/16 --gateway 172.20.0.1"
  run_batch_add "${k3d_command}"
  run_batch_execute
}

function install_kubectl {
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
  KUBECTL_CHECKSUM=$(curl -sL https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256)
  run_batch_new
  run_batch_add "curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  run_batch_add "echo ${KUBECTL_CHECKSUM}  kubectl | sha256sum --check"
  run_batch_add "sudo mv /home/${SSHUSER}/kubectl /usr/local/bin/"
  run_batch_add 'sudo chmod +x /usr/local/bin/kubectl'
  run_batch_add "kubectl config use-context k3d-k3s-default"
  run_batch_add "kubectl cluster-info && kubectl get nodes"
  run_batch_execute

  echo "copying kubeconfig to workstation..."
  mkdir -p ~/.kube
  scp -i ${SSHKEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${SSHUSER}@${PublicIP}:/home/${SSHUSER}/.kube/config ~/.kube/${KUBECONFIG}
  if [[ "$PRIVATE_IP" == true ]]; then
    $sed_gsed -i "s/0\.0\.0\.0/${PrivateIP}/g" ~/.kube/${KUBECONFIG}
  else # default is to use public ip
    $sed_gsed -i "s/0\.0\.0\.0/${PublicIP}/g" ~/.kube/${KUBECONFIG}
  fi
}

function install_metallb {
  # Handle MetalLB cluster resource creation
  if [[ "${METAL_LB}" == true || "${ATTACH_SECONDARY_IP}" == true ]]; then
    echo "Installing MetalLB..."
    run_batch_new
  
    until [[ ${REGISTRY_USERNAME} ]]; do
      read -p "Please enter your Registry1 username: " REGISTRY_USERNAME
    done
    until [[ ${REGISTRY_PASSWORD} ]]; do
      read -s -p "Please enter your Registry1 password: " REGISTRY_PASSWORD
    done

    scp -r -i ${SSHKEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${SCRIPT_DIR}/metallb ${SSHUSER}@${PublicIP}:/tmp/
    
    run_batch_add "kubectl create namespace metallb-system"
    run_batch_add "kubectl create secret docker-registry registry1 \
      --docker-server=registry1.dso.mil \
      --docker-username=${REGISTRY_USERNAME} \
      --docker-password=${REGISTRY_PASSWORD} \
      -n metallb-system"

    run_batch_add "kubectl apply -k /tmp/metallb"
    # Wait for controller to be live so that validating webhooks function when we apply the config
    run_batch_add 'echo "Waiting for MetalLB controller..."'
    run_batch_add "kubectl wait --for=condition=available --timeout 300s -n metallb-system deployment controller"
    run_batch_add 'echo "MetalLB is installed"'


    if [[ "$METAL_LB" == true ]]; then
      echo "Building MetalLB configuration for -m mode."
      cat << EOF > ${TMPDIR}/metallb-config.yaml
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
    elif [[ "$ATTACH_SECONDARY_IP" == true ]]; then
      echo "Building MetalLB configuration for -a mode."
      cat <<EOF > ${TMPDIR}/metallb-config.yaml
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

    cat <<EOF > ${TMPDIR}/primaryProxy.yaml
ports:
  443.tcp:
    - 172.20.1.241
settings:
  workerConnections: 1024
EOF

    cat <<EOF > ${TMPDIR}/secondaryProxy.yaml
ports:
  443.tcp:
    - 172.20.1.240
settings:
  workerConnections: 1024
EOF

      scp -i ${SSHKEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${TMPDIR}/primaryProxy.yaml ${SSHUSER}@${PublicIP}:/home/${SSHUSER}/
      scp -i ${SSHKEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${TMPDIR}/secondaryProxy.yaml ${SSHUSER}@${PublicIP}:/home/${SSHUSER}/
      run_batch_add "docker run -d --name=primaryProxy --network=k3d-network -p $PrivateIP:443:443  -v /home/${SSHUSER}/primaryProxy.yaml:/etc/confd/values.yaml ghcr.io/k3d-io/k3d-proxy:$K3D_VERSION"
      run_batch_add "docker run -d --name=secondaryProxy --network=k3d-network -p $(getPrivateIP2):443:443 -v /home/${SSHUSER}/secondaryProxy.yaml:/etc/confd/values.yaml ghcr.io/k3d-io/k3d-proxy:$K3D_VERSION"
    fi

    scp -i ${SSHKEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${TMPDIR}/metallb-config.yaml ${SSHUSER}@${PublicIP}:/home/${SSHUSER}/
    run_batch_add "kubectl create -f /home/${SSHUSER}/metallb-config.yaml"
    run_batch_execute
  fi
}

function print_instructions {
  echo
  echo "================================================================================"
  echo "====================== DEPLOYMENT FINISHED ====================================="
  echo "================================================================================"
  # ending instructions
  echo
  echo "SAVE THE FOLLOWING INSTRUCTIONS INTO A TEMPORARY TEXT DOCUMENT SO THAT YOU DON'T LOSE THEM"
  if [[ "$TERMINATE_INSTANCE" != "false" ]]; then
    echo "NOTE: The EC2 instance will automatically terminate 8 hours from the time of creation unless you delete the root cron job"
  fi
  echo
  echo "ssh to instance:"
  echo "  ssh -i ${SSHKEY} -o IdentitiesOnly=yes ${SSHUSER}@${PublicIP}"
  echo
  echo "To use kubectl from your local workstation you must set the KUBECONFIG environment variable:"
  echo "  export KUBECONFIG=~/.kube/${KUBECONFIG}"
  if [[ "$PRIVATE_IP" == true ]]; then
    echo "The cluster connection will not work until you start sshuttle as described below."
  fi
  echo

  if [[ "$METAL_LB" == true ]] ; then     # using MetalLB
    if [[ "$PRIVATE_IP" == true ]]; then # using MetalLB and private IP
      echo "Start sshuttle in a separate terminal window:"
      echo "  sshuttle --dns -vr ${SSHUSER}@${PublicIP} 172.31.0.0/16 --ssh-cmd 'ssh -i ${SSHKEY} -D 127.0.0.1:12345'"
      echo "Do not edit /etc/hosts on your local workstation."
      echo "Edit /etc/hosts on the EC2 instance. Sample /etc/host entries have already been added there."
      echo "Manually add more hostnames as needed."
      echo "The IPs to use come from the istio-system services of type LOADBALANCER EXTERNAL-IP that are created when Istio is deployed."
      echo "You must use Firefox browser with with manual SOCKs v5 proxy configuration to localhost with port 12345."
      echo "Also ensure 'Proxy DNS when using SOCKS v5' is checked."
      echo "Or, with other browsers like Chrome you could use a browser plugin like foxyproxy to do the same thing as Firefox."
    else # using MetalLB and public IP
      echo "OPTION 1: ACCESS APPLICATIONS WITH WEB BROWSER ONLY"
      echo "To access apps from browser only start ssh with application-level port forwarding:"
      echo "  ssh -i ${SSHKEY} ${SSHUSER}@${PublicIP} -D 127.0.0.1:12345"
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
      echo "  sshuttle --dns -vr ${SSHUSER}@${PublicIP} 172.20.1.0/24 --ssh-cmd 'ssh -i ${SSHKEY}'"
      echo "Edit your workstation /etc/hosts to add the LOADBALANCER EXTERNAL-IPs from the istio-system services with application hostnames."
      echo "Here is an example. You might have to change this depending on the number of gateways you configure for k8s cluster."
      echo "  # METALLB ISTIO INGRESS IPs"
      echo "  172.20.1.240 keycloak.dev.bigbang.mil vault.dev.bigbang.mil"
      echo "  172.20.1.241 sonarqube.dev.bigbang.mil prometheus.dev.bigbang.mil nexus.dev.bigbang.mil gitlab.dev.bigbang.mil"
    fi
  elif [[ "$PRIVATE_IP" == true ]]; then # not using MetalLB
    # Not using MetalLB and using private IP
    echo "Start sshuttle in a separate terminal window:"
    echo "  sshuttle --dns -vr ${SSHUSER}@${PublicIP} 172.31.0.0/16 --ssh-cmd 'ssh -i ${SSHKEY}'"
    echo
    echo "To access apps from a browser edit your /etc/hosts to add the private IP of your EC2 instance with application hostnames. Example:"
    echo "  ${PrivateIP}  gitlab.dev.bigbang.mil prometheus.dev.bigbang.mil kibana.dev.bigbang.mil"
    echo
  else # Not using MetalLB and using public IP. This is the default
    echo "To access apps from a browser edit your /etc/hosts to add the public IP of your EC2 instance with application hostnames."
    echo "Example:"
    echo "  ${PublicIP} gitlab.dev.bigbang.mil prometheus.dev.bigbang.mil kibana.dev.bigbang.mil"
    echo

    if [[ $SecondaryIP ]]; then
      echo "A secondary IP is available for use if you wish to have a passthrough ingress for Istio along with a public Ingress Gateway, this maybe useful for Keycloak x509 mTLS authentication."
      echo "  $SecondaryIP  keycloak.dev.bigbang.mil"
    fi
  fi
}

function initialize_instance {
  ##### Configure Instance
  ## TODO: replace these individual commands with userdata when the spot instance is created?
  echo
  echo
  echo "starting instance config"

  runwithexitcode "grep '^DISTRIB_ID=Ubuntu' /etc/lsb-release"
  if [[ $? -ne 0 ]]; then
    echo "This script only knows how to provision Ubuntu systems. Sorry!"
    exit 1
  fi

  run_batch_new
  run_batch_add "sudo -S -- bash -c 'echo \"$SSHUSER ALL=(ALL:ALL) NOPASSWD: ALL\" | sudo tee /etc/sudoers.d/dont-prompt-$SSHUSER-for-sudo-password;'"
  run_batch_add "sudo -- bash -c \"sysctl -w vm.max_map_count=524288; \
    echo vm.max_map_count=524288 > /etc/sysctl.d/vm-max_map_count.conf; \
    sysctl -w fs.nr_open=13181252; \
    echo fs.nr_open=13181252 > /etc/sysctl.d/fs-nr_open.conf; \
    sysctl -w fs.file-max=13181250; \
    echo fs.file-max=13181250 > /etc/sysctl.d/fs-file-max.conf; \
    echo fs.inotify.max_user_instances=1024 > /etc/sysctl.d/fs-inotify-max_user_instances.conf; \
    sysctl -w fs.inotify.max_user_instances=1024; \
    echo fs.inotify.max_user_watches=1048576 > /etc/sysctl.d/fs-inotify-max_user_watches.conf; \
    sysctl -w fs.inotify.max_user_watches=1048576; \
    echo fs.may_detach_mounts=1 >> /etc/sysctl.d/fs-may_detach_mounts.conf; \
    sysctl -w fs.may_detach_mounts=1; \
    sysctl -p; \
    echo '* soft nofile 13181250' >> /etc/security/limits.d/ulimits.conf; \
    echo '* hard nofile 13181250' >> /etc/security/limits.d/ulimits.conf; \
    echo '* soft nproc  13181250' >> /etc/security/limits.d/ulimits.conf; \
    echo '* hard nproc  13181250' >> /etc/security/limits.d/ulimits.conf; \
    modprobe br_netfilter; \
    modprobe nf_nat_redirect; \
    modprobe xt_REDIRECT; \
    modprobe xt_owner; \
    modprobe xt_statistic; \
    sysctl --system; \
    echo br_netfilter >> /etc/modules-load.d/istio-iptables.conf; \
    echo nf_nat_redirect >> /etc/modules-load.d/istio-iptables.conf; \
    echo xt_REDIRECT >> /etc/modules-load.d/istio-iptables.conf; \
    echo xt_owner >> /etc/modules-load.d/istio-iptables.conf; \
    echo xt_statistic >> /etc/modules-load.d/istio-iptables.conf; \
    systemctl restart systemd-modules-load.service\" "

  if [[ "$INIT_SCRIPT" != "" ]]; then
    echo "Running init script"
    if [[ ! -e ${INIT_SCRIPT} ]]; then
      echo "Init script does not exist"
      exit 1
    fi
    cat ${INIT_SCRIPT} | run "sudo cat > /tmp/k3d-dev-initscript"
    run_batch_add "sudo bash /tmp/k3d-dev-initscript"
  fi

  if [[ "$TERMINATE_INSTANCE" != "false" ]]; then
    echo "Instance will automatically terminate 8 hours from now unless you alter the root crontab"
    run_batch_add "sudo bash -c 'echo \"\$(date -u -d \"+8 hours\" +\"%M %H\") * * * /usr/sbin/shutdown -h now\" | crontab -'"
    echo
  fi

  if [[ $APT_UPDATE = "true" ]]; then
    echo
    run_batch_add 'echo "updating packages"'
    run_batch_add "sudo DEBIAN_FRONTEND=noninteractive apt-get update"
    run_batch_add "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"
  fi
  run_batch_execute

  install_docker
}

function cloud_aws_prep_objects {
  #### Cleaning up unused Elastic IPs
  ALLOCATIONIDs=($(aws ec2 describe-addresses --filters "Name=tag:Owner,Values=${AWSUSERNAME}" "Name=tag:Project,Values=${PROJECTTAG}" --query "Addresses[?AssociationId==null]" | jq -r '.[].AllocationId'))
  for i in "${ALLOCATIONIDs[@]}"; do
    echo -n "Releasing Elastic IP $i ..."
    aws ec2 release-address --allocation-id $i
    echo "done"
  done

  #### SSH Key Pair
  # Create SSH key if it doesn't exist
  echo -n Checking if key pair ${KeyName} exists ...
  aws ec2 describe-key-pairs --output json --no-cli-pager --key-names ${KeyName} >/dev/null 2>&1 || keypair=missing
  if [ "${keypair}" == "missing" ]; then
    echo -n -e "missing\nCreating key pair ${KeyName} ... "
    aws ec2 create-key-pair --output json --no-cli-pager --key-name ${KeyName} | jq -r '.KeyMaterial' >${SSHKEY}
    chmod 600 ${SSHKEY}
    echo done
  else
    echo found
  fi
  if [[ ! -f ${SSHKEY} ]]; then
    echo "Local key file ${SSHKEY} does not exist. Cannot continue." >&2
    exit 1
  fi

  #### Security Group
  # Create security group if it doesn't exist
  echo -n "Checking if security group ${SGname} exists ..."
  aws ec2 describe-security-groups --output json --no-cli-pager --group-names ${SGname} >/dev/null 2>&1 || secgrp=missing
  if [ "${secgrp}" == "missing" ]; then
    echo -e "missing\nCreating security group ${SGname} ... "
    aws ec2 create-security-group --output json --no-cli-pager --description "IP based filtering for ${SGname}" --group-name ${SGname} --vpc-id ${VPC_ID}
    echo done
  else
    echo found
  fi
}

function cloud_aws_request_spot_instance
{
  ##### Launch Specification
  # Typical settings for Big Bang development
  InstanceType="${InstSize}"
  VolumeSize=120

  echo "Using AMI image id ${AMI_ID}"
  ImageId="${AMI_ID}"

  # Create the device mapping and spot options JSON files
  echo "Creating device_mappings.json ..."

  # gp3 volumes are 20% cheaper than gp2 and comes with 3000 Iops baseline and 125 MiB/s baseline throughput for free.
  cat <<EOF >${TMPDIR}/device_mappings.json
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
  cat <<EOF >${TMPDIR}/spot_options.json
{
  "MarketType": "spot",
  "SpotOptions": {
    "MaxPrice": "${SpotPrice}",
    "SpotInstanceType": "one-time"
  }
}
EOF

  #### Request a Spot Instance

  # Run a spot instance with our launch spec for the max. of 6 hours
  # NOTE: t3a.2xlarge spot price is 0.35 m5a.4xlarge is 0.69
  echo "Running spot instance ..."

  if [[ "${ATTACH_SECONDARY_IP}" == true ]]; then
    # If we are using a secondary IP, we don't want to assign public IPs at launch time. Instead, the script will attach both public IPs after the instance is launched.
    additional_create_instance_options="--no-associate-public-ip-address --secondary-private-ip-address-count 1"
  else
    additional_create_instance_options="--associate-public-ip-address"
  fi

  InstId=$(aws ec2 run-instances \
    --output json --no-paginate \
    --count 1 --image-id "${ImageId}" \
    --instance-type "${InstanceType}" \
    --subnet-id "${SUBNET_ID}" \
    --key-name "${KeyName}" \
    --security-group-ids "${SecurityGroupId}" \
    --instance-initiated-shutdown-behavior "terminate" \
    --block-device-mappings file://${TMPDIR}/device_mappings.json \
    --instance-market-options file://${TMPDIR}/spot_options.json \
    ${additional_create_instance_options} |
    jq -r '.Instances[0].InstanceId')

  # Check if spot instance request was not created
  if [ -z ${InstId} ]; then
    exit 1
  fi

  # Add name tag to spot instance
  aws ec2 create-tags --resources ${InstId} --tags Key=Name,Value=${AWSUSERNAME}-dev &>/dev/null
  aws ec2 create-tags --resources ${InstId} --tags Key=Project,Value=${PROJECTTAG} &>/dev/null

  # Request was created, now you need to wait for it to be filled
  echo "Waiting for instance ${InstId} to be ready ..."
  aws ec2 wait instance-running --output json --no-cli-pager --instance-ids ${InstId} &>/dev/null

  # allow some extra seconds for the instance to be fully initialized
  echo "Almost there, 15 seconds to go..."
  sleep 15
}

function cloud_aws_assign_ip_addresses
{
  ## IP Address Allocation and Attachment
  CURRENT_EPOCH=$(date +'%s')

  # Get the private IP address of our instance
  PrivateIP=$(aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')

  # Use Elastic IPs if a Secondary IP is required, instead of the auto assigned one.
  if [[ "${ATTACH_SECONDARY_IP}" == false ]]; then
    PublicIP=$(aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PublicIpAddress')
  else
    echo "Checking to see if an Elastic IP is already allocated and not attached..."
    PublicIP=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=${AWSUSERNAME}-EIP1" "Name=tag:Project,Values=${PROJECTTAG}" --query 'Addresses[?AssociationId==null]' | jq -r '.[0].PublicIp // ""')
    if [[ -z "${PublicIP}" ]]; then
      echo "Allocating a new/another primary elastic IP..."
      PublicIP=$(aws ec2 allocate-address --output json --no-cli-pager --tag-specifications="ResourceType=elastic-ip,Tags=[{Key=Name,Value=${AWSUSERNAME}-EIP1},{Key=Owner,Value=${AWSUSERNAME}}]" | jq -r '.PublicIp')
    else
      echo "Previously allocated primary Elastic IP ${PublicIP} found."
    fi

    echo -n "Associating IP ${PublicIP} address to instance ${InstId} ..."
    EIP1_ASSOCIATION_ID=$(aws ec2 associate-address --output json --no-cli-pager --instance-id ${InstId} --private-ip ${PrivateIP} --public-ip $PublicIP | jq -r '.AssociationId')
    echo "${EIP1_ASSOCIATION_ID}"
    EIP1_ID=$(aws ec2 describe-addresses --public-ips ${PublicIP} | jq -r '.Addresses[].AllocationId')
    aws ec2 create-tags --resources ${EIP1_ID} --tags Key="lastused",Value="${CURRENT_EPOCH}"
    aws ec2 create-tags --resources ${EIP1_ID} --tags Key="Project",Value="${PROJECTTAG}"

    PrivateIP2=$(getPrivateIP2)
    echo "Checking to see if a Secondary Elastic IP is already allocated and not attached..."
    SecondaryIP=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=${AWSUSERNAME}-EIP2" "Name=tag:Project,Values=${PROJECTTAG}" --query 'Addresses[?AssociationId==null]' | jq -r '.[0].PublicIp // ""')
    if [[ -z "${SecondaryIP}" ]]; then
      echo "Allocating a new/another secondary elastic IP..."
      SecondaryIP=$(aws ec2 allocate-address --output json --no-cli-pager --tag-specifications="ResourceType=elastic-ip,Tags=[{Key=Name,Value=${AWSUSERNAME}-EIP2},{Key=Owner,Value=${AWSUSERNAME}}]" | jq -r '.PublicIp')
    else
      echo "Previously allocated secondary Elastic IP ${SecondaryIP} found."
    fi
    echo -n "Associating Secondary IP ${SecondaryIP} address to instance ${InstId}..."
    EIP2_ASSOCIATION_ID=$(aws ec2 associate-address --output json --no-cli-pager --instance-id ${InstId} --private-ip $(getPrivateIP2) --public-ip $SecondaryIP | jq -r '.AssociationId')
    echo "${EIP2_ASSOCIATION_ID}"
    EIP2_ID=$(aws ec2 describe-addresses --public-ips ${SecondaryIP} | jq -r '.Addresses[].AllocationId')
    aws ec2 create-tags --resources ${EIP2_ID} --tags Key="lastused",Value="${CURRENT_EPOCH}"
    aws ec2 create-tags --resources ${EIP2_ID} --tags Key="Project",Value="${PROJECTTAG}"
    echo "Secondary public IP is ${SecondaryIP}"
  fi  
}

function cluster_mgmt_select_action_for_existing {
  echo "💣 Big Bang Cluster Management 💣"
  PS3="Please select an option: "
  options=("Re-create K3D cluster" "Recreate the cloud instance from scratch" "Do Nothing")

  select opt in "${options[@]}"; do
    case $opt in
    "Re-create K3D cluster")
      read -p "Are you sure you want to re-create a K3D cluster on this instance (y/n)? " -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo
        exit 1
      fi
      RESET_K3D=true
      SecondaryIP=$(aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddresses[] | select(.Primary==false) | .Association.PublicIp')
      PrivateIP2=$(getPrivateIP2)
      if [[ "${ATTACH_SECONDARY_IP}" == true && -z "${SecondaryIP}" ]]; then
        echo "Secondary IP didn't exist at the time of creation of the instance, so cannot attach one without re-creating it with the -a flag selected."
        exit 1
      fi
      break
      ;;
    "Recreate the cloud instance from scratch")
      # Code for recreating the EC2 instance from scratch
      CLOUD_RECREATE_INSTANCE=true
      break
      ;;
    "Do Nothing")
      echo "Doing nothing..."
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
    esac
  done
}

function cloud_aws_create_instances {
  echo "Checking for existing cluster for ${AWSUSERNAME}."
  InstId=$(aws ec2 describe-instances \
    --output text \
    --query "Reservations[].Instances[].InstanceId" \
    --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=tag:Project,Values=${PROJECTTAG}" "Name=instance-state-name,Values=running")
  if [[ $InstId ]]; then
    PublicIP=$(aws ec2 describe-instances --output text --no-cli-pager --instance-id ${InstId} --query "Reservations[].Instances[].PublicIpAddress")
    PrivateIP=$(aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${InstId} | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')    
    echo "Existing cluster found running on instance ${InstId} on ${PublicIP} / ${PrivateIP}"
    if [[ "${RESET_K3D}" != "true" ]] && [[ "${CLOUD_RECREATE_INSTANCE}" != "true" ]]; then
      cluster_mgmt_select_action_for_existing
    fi
    if [[ "${CLOUD_RECREATE_INSTANCE}" == "true" ]]; then
      destroy_instances
    fi
  fi

  if [[ "${RESET_K3D}" == false ]] ; then
    if [[ "$BIG_INSTANCE" == true ]]; then
      echo "Will use large m5a.4xlarge spot instance"
      InstSize="m5a.4xlarge"
      SpotPrice="0.69"
    else
      echo "Will use standard t3a.2xlarge spot instance"
      InstSize="t3a.2xlarge"
      SpotPrice="0.35"
    fi

    cloud_aws_prep_objects
    update_ec2_security_group
    cloud_aws_request_spot_instance
    cloud_aws_assign_ip_addresses

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
  fi
}

function fix_etc_hosts {
    if [[ "$METAL_LB" == "true" ]]; then
      run <<ENDSSH
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
    sudo bash -c "echo $(getPrivateIP2)  keycloak.dev.bigbang.mil vault.dev.bigbang.mil >> /etc/hosts"
    sudo bash -c "echo $PrivateIP anchore-api.dev.bigbang.mil anchore.dev.bigbang.mil argocd.dev.bigbang.mil gitlab.dev.bigbang.mil registry.dev.bigbang.mil tracing.dev.bigbang.mil kiali.dev.bigbang.mil kibana.dev.bigbang.mil chat.dev.bigbang.mil minio.dev.bigbang.mil minio-api.dev.bigbang.mil alertmanager.dev.bigbang.mil grafana.dev.bigbang.mil prometheus.dev.bigbang.mil nexus.dev.bigbang.mil sonarqube.dev.bigbang.mil tempo.dev.bigbang.mil twistlock.dev.bigbang.mil >> /etc/hosts"
    sudo bash -c "echo '## end dev.bigbang.mil section' >> /etc/hosts"
    # run kubectl to add keycloak and vault's hostname/IP to the configmap for coredns, restart coredns
    kubectl get configmap -n kube-system coredns -o yaml | sed '/^    .* host.k3d.internal$/a\ \ \ \ $(getPrivateIP2) keycloak.dev.bigbang.mil vault.dev.bigbang.mil' | kubectl apply -f -
    kubectl delete pod -n kube-system -l k8s-app=kube-dns
ENDSSH
  fi
}

function create_instances {
  if [[ "${PublicIP}" == "" ]]; then
    cloud_${CLOUDPROVIDER}_create_instances
  fi
  initialize_instance
  install_k3d
  install_kubectl
  install_metallb
  fix_etc_hosts
  if [[ "${QUIET}" == "false" ]]; then
    print_instructions
  fi
}

function main {
  process_arguments "$@"

  extratools=""
  if [[ "${CLOUDPROVIDER}" != "" ]]; then
    extratools=$(cloud_${CLOUDPROVIDER}_toolnames)
  fi
  check_missing_tools ${extratools}

  # When -H is NOT provided, we assume we're responsible
  # for provisioning the cloud infra.
  if [[ "$PublicIP" == "" ]]; then
    cloud_${CLOUDPROVIDER}_configure
  else
    CLOUDPROVIDER=""
  fi

  set_kubeconfig

  ${action}
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main $@
  exit $?
fi
