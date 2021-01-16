## TODO: Revisit the terraform gitlab http backend
# terraform {
#   backend "http" {}
# }

provider "aws" {
  region = var.aws_region
}


locals {
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, ceil(log(6, 2)), 0),
    cidrsubnet(var.vpc_cidr, ceil(log(6, 2)), 1),
  ]

  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, ceil(log(6, 2)), 2),
    cidrsubnet(var.vpc_cidr, ceil(log(6, 2)), 3),
  ]

  intra_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, ceil(log(6, 2)), 4),
    cidrsubnet(var.vpc_cidr, ceil(log(6, 2)), 5),
  ]

  name = "umbrella-${var.env}"

  tags = {
    "terraform"       = "true",
    "env"             = var.env,
    "project"         = "umbrella",
    "ci_pipeline_url" = var.ci_pipeline_url
  }
}

#
# Network
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets  = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs
  intra_subnets   = local.intra_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Use AWS VPC private endpoints to mirror functionality on airgapped (T)C2S environments
  #   S3: for some vendors cluster bootstrapping/artifact storage
  #   STS: for caller identity checks
  #   EC2: for cloud manager type requests (such as auto ebs provisioning)
  #   ASG: for cluster autoscaler
  #   ELB: for auto elb provisioning
  enable_s3_endpoint                   = true
  enable_sts_endpoint                  = true
  enable_ec2_endpoint                  = true
  enable_ec2_autoscaling_endpoint      = true
  enable_elasticloadbalancing_endpoint = true

  ec2_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  ec2_endpoint_subnet_ids          = module.vpc.intra_subnets
  ec2_endpoint_private_dns_enabled = true

  ec2_autoscaling_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  ec2_autoscaling_endpoint_subnet_ids          = module.vpc.intra_subnets
  ec2_autoscaling_endpoint_private_dns_enabled = true

  elasticloadbalancing_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  elasticloadbalancing_endpoint_subnet_ids          = module.vpc.intra_subnets
  elasticloadbalancing_endpoint_private_dns_enabled = true

  sts_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  sts_endpoint_subnet_ids          = module.vpc.intra_subnets
  sts_endpoint_private_dns_enabled = true

  # Prevent creation of EIPs for NAT gateways
  reuse_nat_ips = false

  # Add in required tags for proper AWS CCM integration
  public_subnet_tags = merge({
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }, local.tags)

  private_subnet_tags = merge({
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }, local.tags)

  intra_subnet_tags = merge({
    "kubernetes.io/cluster/${local.name}" = "shared"
  }, local.tags)

  tags = merge({
    "kubernetes.io/cluster/${local.name}" = "shared"
  }, local.tags)
}

# Shared Private Endpoint Security Group
resource "aws_security_group" "endpoints" {
  name        = "${local.name}-endpoint"
  description = "${local.name} endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# TGW Attachments
# Attaches the management vpc (the hub) to the created vpc (the spokes).
#
module "spoke" {
  source = "git::https://repo1.dsop.io/platform-one/big-bang/terraform-modules/spoke-tgw-attachments.git"

  name       = local.name
  hub_vpc_id = var.hub_vpc_id
  hub_tgw    = var.hub_tgw
  hub_tgw_rt = var.hub_tgw_rt
  hub_tgwa   = var.hub_tgwa

  spoke_vpc_id  = module.vpc.vpc_id
  spoke_subnets = module.vpc.private_subnets
  spoke_rt_ids  = module.vpc.private_route_table_ids
}
