locals {
  name = "umbrella-${var.env}"

  # Bigbang specific OS tuning
  os_prep = <<EOF
# Configure aws cli default region to current region, it'd be great if the aws cli did this on install........
aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Tune vm sysctl for elasticsearch
sysctl -w vm.max_map_count=524288

# SonarQube host pre-requisites
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192

# Preload kernel modules required by istio-init, required for selinux enforcing instances using istio-init
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
# Persist modules after reboots
printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules
EOF

  tags = {
    "project"         = "umbrella"
    "env"             = var.env
    "terraform"       = "true",
    "ci_pipeline_url" = var.ci_pipeline_url
  }
}

module "rke2" {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git?ref=v1.1.8"

  cluster_name          = local.name
  vpc_id                = var.vpc_id
  subnets               = var.private_subnets
  ami                   = var.server_ami
  servers               = var.servers
  instance_type         = var.server_instance_type
  ssh_authorized_keys   = var.ssh_authorized_keys
  controlplane_internal = var.controlplane_internal
  rke2_version          = var.rke2_version

  rke2_config = <<EOF
disable:
  - rke2-ingress-nginx
EOF

  block_device_mappings = {
    size = 100
    encrypted = true
    type = "gp3"
  }

  enable_ccm = var.enable_ccm
  download   = var.download

  pre_userdata = local.os_prep

  tags = merge({}, local.tags, var.tags)
}

module "generic_agents" {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git//modules/agent-nodepool?ref=v1.1.8"

  name                = "generic-agent"
  vpc_id              = var.vpc_id
  subnets             = var.private_subnets
  ami                 = var.agent_ami
  asg                 = var.agent_asg
  spot                = var.agent_spot
  instance_type       = var.agent_instance_type
  ssh_authorized_keys = var.ssh_authorized_keys
  rke2_version        = var.rke2_version

  enable_ccm        = var.enable_ccm
  enable_autoscaler = var.enable_autoscaler
  download          = var.download

  # TODO: These need to be set in pre-baked ami's
  pre_userdata = local.os_prep

  block_device_mappings = {
    size = 150
    encrypted = true
    type = "gp3"
  }

  # Required data for identifying cluster to join
  cluster_data = module.rke2.cluster_data

  tags = merge({}, local.tags, var.tags)
}

# Example method of fetching kubeconfig from state store, requires aws cli
resource "null_resource" "kubeconfig" {
  depends_on = [module.rke2]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws s3 cp ${module.rke2.kubeconfig_path} rke2.yaml"
  }
}

## Adding tags on VPC and Subnets to match uniquely created cluster name
resource "aws_ec2_tag" "vpc_tags" {
  resource_id = var.vpc_id
  key         = "kubernetes.io/cluster/${module.rke2.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_subnets_tags" {
  count       = length(var.public_subnets)
  resource_id = var.public_subnets[count.index]
  key         = "kubernetes.io/cluster/${module.rke2.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnets_tags" {
  count       = length(var.private_subnets)
  resource_id = var.private_subnets[count.index]
  key         = "kubernetes.io/cluster/${module.rke2.cluster_name}"
  value       = "shared"
}

output "cluster_sg" {
  description = "Cluster SG ID, used for dev ssh access"
  value = module.rke2.cluster_data.cluster_sg
}