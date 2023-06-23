locals {
  name = "umbrella-${var.env}"
  tags = {
    "project"         = "umbrella"
    "env"             = var.env
    "terraform"       = "true",
    "ci_pipeline_url" = var.ci_pipeline_url
    "organization" = var.organization
    "provisioned_using" = "Terraform"
  }

  # Bigbang specific OS tuning
  os_prep = <<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex
echo "AWS Configure"
# Configure aws cli default region to current region, it'd be great if the aws cli did this on install........
aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

#echo "IPTables Confguration"
# iptables rules needed based on https://docs.rke2.io/install/requirements/#networking
#iptables -A INPUT -p tcp -m tcp --dport 2379 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 2380 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 9345 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 6443 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p udp -m udp --dport 8472 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 10250 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 30000:32767 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 4240 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 179 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p udp -m udp --dport 4789 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 5473 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 9098 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 9099 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p udp -m udp --dport 51820 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p udp -m udp --dport 51821 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
#iptables -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Grouping sudo commands to increase node spin up time
echo "Update sysem values"
#sudo -- sh -c 'service iptables save; \
sudo -- sh -c 'sysctl -w vm.max_map_count=524288; \
               echo "vm.max_map_count=524288" > /etc/sysctl.d/vm-max_map_count.conf; \
               sysctl -w fs.nr_open=13181252; \
               echo "fs.nr_open=13181252" > /etc/sysctl.d/fs-nr_open.conf; \
               sysctl -w fs.file-max=13181250; \
               echo "fs.file-max=13181250" > /etc/sysctl.d/fs-file-max.conf; \
               echo "* soft nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
               echo "* hard nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
               echo "* soft nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
               echo "* hard nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
               echo "fs.inotify.max_user_instances=1024" > /etc/sysctl.d/fs-inotify-max_user_instances.conf; \
               sysctl -w fs.inotify.max_user_instances=1024; \
               echo "fs.inotify.max_user_watches=1048576" > /etc/sysctl.d/fs-inotify-max_user_watches.conf; \
               sysctl -w fs.inotify.max_user_watches=1048576; \
               sysctl -p'
#               sysctl -p; \
#               modprobe xt_REDIRECT; \
#               modprobe xt_owner; \
#               modprobe xt_statistic'

# Persist modules after reboots
printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules

echo "Join the Cluster"
#/etc/eks/bootstrap.sh cluster_name
--//--

EOF

  block_device_mappings = {
    size = 150
    encrypted = true
    type = "gp3"
  }

}

module "eks" {
  source              = "git::https://repo1.dso.mil/platform-one/distros/aws/aws-eks-tf.git//eks-tf/terraform/modules/eks"
  cluster_name        = var.cluster_name
  k8s_version         = var.k8s_version
  organization        = var.organization
  env                 = var.env
  ng_desired_size     = var.ng_desired_size
  ng_max_size         = var.ng_max_size
  ng_min_size         = var.ng_min_size
  cluster_instance_types = var.cluster_instance_types
  private_subnet_ids  = var.private_subnets
  public_access_cidrs = var.public_access_cidrs
  policy_arn_prefix   = var.policy_arn_prefix
  cluster_log_types   = ["api","audit","authenticator","controllerManager","scheduler"]
  tags                = merge({}, local.tags, var.tags)
  use_launch_config   = true
  userdata            = local.os_prep
  block_device_mappings = local.block_device_mappings
}

## Adding tags on VPC and Subnets to match uniquely created cluster name
resource "aws_ec2_tag" "vpc_tags" {
  resource_id = var.vpc_id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_subnets_tags" {
  count       = length(var.public_subnets)
  resource_id = var.public_subnets[count.index]
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnets_tags" {
  count       = length(var.private_subnets)
  resource_id = var.private_subnets[count.index]
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}
