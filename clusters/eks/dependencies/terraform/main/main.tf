provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# We are using the IRSA created below for permissions
# However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
# and then turn this off after the cluster/node group is created. Without this initial policy,
# the VPC CNI fails to assign IPs and nodes cannot join the cluster
# See https://github.com/aws/containers-roadmap/issues/1666 for more context
# TODO - remove this policy once AWS releases a managed version similar to AmazonEKS_CNI_Policy (IPv4)

################################################################################
# EKS Module
################################################################################

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "19.15.2"
  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true
  #cluster_endpoint_public_access_cidrs = var.public_access_cidrs
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.private_subnets
  cluster_ip_family          = "ipv4"
  create_cni_ipv6_iam_policy = false
  manage_aws_auth_configmap  = false
  cluster_enabled_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = var.cluster_instance_types

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false
      min_size     = var.ng_min_size
      max_size     = var.ng_max_size
      desired_size = var.ng_desired_size
      disk_size = 50
      create_iam_role = false
      iam_role_arn = "arn:aws-us-gov:iam::${local.account_id}:role/EKSPipelineOpsRole"
    }
  }
}

## CNI Policy ##
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv6   = false

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

## Tag the Public Subnets for ELB purposes ##
locals {
  environment = var.env
}

data "aws_subnets" "subnets" {
  filter {
    name   = "tag:Name"
    values = ["*${local.environment}*"]
  }
}

resource "aws_ec2_tag" "pub_subnet" {
  for_each    = toset(data.aws_subnets.subnets.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}


## Below is for creating EBS addon and policy ##

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.7.0"
  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${var.cluster_name}"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.20.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}


# ## Create Node Group IAM Role ##
# resource "aws_iam_role" "eks_nodegroup_role" {
#   name = "${var.organization}-${var.env}-cluster-nodegroup-role"
#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }
# ## Attach Policies to Node Group Role ##
# resource "aws_iam_role_policy_attachment" "eks_AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:${var.policy_arn_prefix}:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_nodegroup_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:${var.policy_arn_prefix}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_nodegroup_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:${var.policy_arn_prefix}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_nodegroup_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_InstanceOpsKmsPolicy" {
#   policy_arn = aws_iam_policy.KmsPolicy.arn
#   role       = aws_iam_role.eks_nodegroup_role.name
# }

# ## KMS Policy Creation for Vault ##
# data "aws_iam_policy_document" "KmsPolicy" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "kms:DescribeCustomKeyStores",
#       "kms:ListKeys",
#       "kms:DeleteCustomKeyStore",
#       "kms:GenerateRandom",
#       "kms:UpdateCustomKeyStore",
#       "kms:ListAliases",
#       "kms:DisconnectCustomKeyStore",
#       "kms:CreateKey",
#       "kms:ConnectCustomKeyStore",
#       "kms:CreateCustomKeyStore"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "kms:*"
#     ]
#     resources = ["arn:aws-us-gov:kms:us-gov-west-1:141078740716:key/4a90c90f-6199-43e8-aae0-9b2395691abe"]
#   }
# }

# resource "aws_iam_policy" "KmsPolicy" {
#   name   = "KmsPolicy"
#   policy = data.aws_iam_policy_document.KmsPolicy.json
# }
