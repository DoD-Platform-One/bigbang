locals {
  name = "umbrella-${var.env}"

  tags = {
    "project"   = "umbrella"
    "env"       = var.env
    "terraform" = "true"
  }
}

module "rke2" {
  source = "git::https://github.com/rancherfederal/rke2-aws-tf.git"

  cluster_name          = local.name
  vpc_id                = var.vpc_id
  subnets               = var.private_subnets
  ami                   = var.server_ami
  servers               = var.servers
  instance_type         = var.server_instance_type
  ssh_authorized_keys   = var.ssh_authorized_keys
  controlplane_internal = var.controlplane_internal
  rke2_version          = var.rke2_version

  enable_ccm = var.enable_ccm
  download   = var.download

  # TODO: These need to be set in pre-baked ami's
  pre_userdata = <<-EOF
# Temporarily disable selinux enforcing due to missing policies in containerd
# The change is currently being upstreamed and can be tracked here: https://github.com/rancher/k3s/issues/2240
setenforce 0

# Tune vm sysctl for elasticsearch
sysctl -w vm.max_map_count=262144
EOF

  tags = merge({}, local.tags, var.tags)
}

module "generic_agents" {
  source = "git::https://github.com/rancherfederal/rke2-aws-tf.git//modules/agent-nodepool"

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
  pre_userdata = <<-EOF
# Temporarily disable selinux enforcing due to missing policies in containerd
# The change is currently being upstreamed and can be tracked here: https://github.com/rancher/k3s/issues/2240
setenforce 0

# Tune vm sysct for elasticsearch
sysctl -w vm.max_map_count=262144
EOF

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