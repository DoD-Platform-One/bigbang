locals {
  name = "umbrella-${var.env}"

  # Bigbang specific OS tuning
  os_prep = <<EOF
# Configure aws cli default region to current region, it'd be great if the aws cli did this on install........
aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Poor man's partition for ephemeral storage and RKE2 data dir
mkfs -t xfs /dev/nvme2n1
mkdir -p /var/lib/rancher
mount /dev/nvme2n1 /var/lib/rancher
mkdir -p /var/lib/rancher/rke2
mkdir -p /var/lib/rancher/kubelet
ln -s /var/lib/rancher/kubelet /var/lib/kubelet

# iptables rules needed based on https://docs.rke2.io/install/requirements/#networking
iptables -A INPUT -p tcp -m tcp --dport 2379 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 2380 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 9345 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 6443 -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 8472 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 10250 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 30000:32767 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 4240 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 179 -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 4789 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 5473 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 9098 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 9099 -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 51820 -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 51821 -m state --state NEW -j ACCEPT
iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Grouping sudo commands to increase node spin up time
sudo -- sh -c 'service iptables save; \
               sysctl -w vm.max_map_count=524288; \
               echo "vm.max_map_count=524288" > /etc/sysctl.d/vm-max_map_count.conf; \
               sysctl -w fs.nr_open=13181252; \
               echo "fs.nr_open=13181252" > /etc/sysctl.d/fs-nr_open.conf; \
               sysctl -w fs.file-max=13181250; \
               echo "fs.file-max=13181250" > /etc/sysctl.d/fs-file-max.conf; \
               echo "* soft nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
               echo "* hard nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
               echo "* soft nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
               echo "* hard nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
               sysctl -p; \
               modprobe xt_REDIRECT; \
               modprobe xt_owner; \
               modprobe xt_statistic'

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

# AMI Datasource
data "aws_ami" "cisal2" {
  most_recent = true
  owners      = ["345084742485"]

  filter {
    name   = "product-code"
    # CIS Amazon Linux 2 Benchmark - STIG
    values = ["cynhm1j9d2839l7ehzmnes1n0"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "rke2" {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git?ref=v2.1.0"

  cluster_name          = local.name
  vpc_id                = var.vpc_id
  subnets               = var.private_subnets
  ami                   = data.aws_ami.cisal2.image_id
  servers               = var.servers
  instance_type         = var.server_instance_type
  ssh_authorized_keys   = var.ssh_authorized_keys
  controlplane_internal = var.controlplane_internal
  rke2_version          = var.rke2_version
  iam_instance_profile  = var.iam_instance_profile

  rke2_config = var.rke2_config

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
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git//modules/agent-nodepool?ref=v2.1.0"

  name                 = "generic-agent"
  vpc_id               = var.vpc_id
  subnets              = var.private_subnets
  ami                  = data.aws_ami.cisal2.image_id
  asg                  = var.agent_asg
  spot                 = var.agent_spot
  instance_type        = var.agent_instance_type
  ssh_authorized_keys  = var.ssh_authorized_keys
  rke2_version         = var.rke2_version
  iam_instance_profile = var.iam_instance_profile

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
