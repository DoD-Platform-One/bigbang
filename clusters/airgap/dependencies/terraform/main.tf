provider "aws" {
  region  = "us-gov-west-1"
}

terraform {
  backend "s3" {
    bucket               = "airgap-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    dynamodb_table       = "airgap-tf-states-lock"
    workspace_key_prefix = "airgap"
  }
}

data "terraform_remote_state" "airgap_s3" {
  backend = "s3"
  config = {
    bucket               = "airgap-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    workspace_key_prefix = "airgap"
  }
  workspace = var.env
}

locals {
  #selects a random subnet from filtered ids
  subnet_ids_list = tolist(data.aws_subnets.ci_subnets.ids)
  subnet_ids_random_index = random_id.index.dec % length(data.aws_subnets.ci_subnets.ids)
  random_subnet_id = local.subnet_ids_list[local.subnet_ids_random_index]
}

resource random_id index {
  byte_length = 4
}

resource "aws_instance" "bb-ci-airgap" {
  ami                    = data.aws_ami.airgap_ami.id
  instance_type          = "m5.2xlarge"
  subnet_id              = local.random_subnet_id
  vpc_security_group_ids = [aws_security_group.airgap_allow_ci.id]
  iam_instance_profile   = "airgap_ci_role"
  key_name               = var.env
  root_block_device {
    volume_size           = "100"
    delete_on_termination = true
  }
  tags = {
    Name            = var.airgap_env_name
    ci_pipeline_url = var.ci_pipeline_url
    env             = var.env
  }
  user_data = <<EOF
#!/bin/bash
sleep 5
mkdir ~/registry
/usr/local/bin/aws s3 cp s3://umbrella-bigbang-releases/umbrella/${var.bb_release}/images.tar.gz ~/
tar -xvf ~/images.tar.gz -C ~/registry
# inject ip for registry mirror
LOCALIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i "s/LOCALIPHERE/$LOCALIP/g" /etc/rancher/k3s/registries.yaml
cat - << REGISTRYEOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["$LOCALIP:5000"]
}
REGISTRYEOF
systemctl restart docker
sleep 5
docker run -d \
  -p 5000:5000 \
  -v ~/registry/var/lib/registry:/var/lib/registry \
  --restart=always \
  --name registry registry:2
INSTALL_K3S_SKIP_DOWNLOAD=true \
  INSTALL_K3S_EXEC="--disable=traefik" \
  INSTALL_K3S_SELINUX_WARN=true \
  INSTALL_K3S_SKIP_SELINUX_RPM=true \
  ./k3s-install.sh
# verify k3s is ready
sleep 30
KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl wait --for=condition=Ready --timeout=120s pods --all --all-namespaces
# create tiny git server
useradd --create-home --shell /bin/bash git
ssh-keygen  -b 4096 -t rsa -f /git.pem -q -N ""
mkdir -p /home/git/.ssh && chmod 700 /home/git/.ssh/
touch /home/git/.ssh/authorized_keys && chmod 600 /home/git/.ssh/authorized_keys
cat /git.pem.pub >> /home/git/.ssh/authorized_keys
# repo prep
/usr/local/bin/aws s3 cp s3://umbrella-bigbang-releases/umbrella/${var.bb_release}/repositories.tar.gz ~/
tar -xvf ~/repositories.tar.gz -C /home/git/
chown -R git:users /home/git/
/usr/local/bin/aws s3 cp /git.pem s3://airgap-tf-states/airgap/${var.env}/git.pem
# inject ip into kuberconfig for external access
sed -i "s/127.0.0.1/$LOCALIP/g" /etc/rancher/k3s/k3s.yaml
/usr/local/bin/aws s3 cp /etc/rancher/k3s/k3s.yaml s3://airgap-tf-states/airgap/${var.env}/airgap_kubeconfig.yaml
EOF
}

data "aws_ami" "airgap_ami" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["bb-airgap-ci-prod*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "ci_vpc" {
  filter {
    name   = "tag:Name"
    values = ["bigbang-ci-cluster-vpc"]
  }
}

data "aws_subnets" "ci_subnets" {
    filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ci_vpc.id]
  }
    filter {
    name   = "tag:Name"
    values = ["bigbang-ci-cluster-private*"]
  }
}

resource "aws_security_group" "airgap_allow_ci" {
  name        = var.airgap_env_name
  description = "Allow CI communication only"
  vpc_id      = data.aws_vpc.ci_vpc.id

  ingress {
    description      = "restricted to ci"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [data.aws_vpc.ci_vpc.cidr_block]
  }

  egress {
    description      = "restricted to ci"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [data.aws_vpc.ci_vpc.cidr_block]
  }

  egress {
    description      = "permit s3"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    prefix_list_ids  = [data.aws_ec2_managed_prefix_list.s3_prefix.id]
  }

  tags = {
    Name            = var.airgap_env_name
    ci_pipeline_url = var.ci_pipeline_url
    env             = var.env
  }
}

data "aws_ec2_managed_prefix_list" "s3_prefix" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.us-gov-west-1.s3"]
  }
}
