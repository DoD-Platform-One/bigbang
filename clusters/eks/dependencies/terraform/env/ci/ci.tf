terraform {
  backend "s3" {
    bucket               = "nightly-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    dynamodb_table       = "nightly-eks-tf-states-lock"
    workspace_key_prefix = "eks"
  }
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket               = "nightly-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    workspace_key_prefix = "aws-networking"
  }
  workspace = var.env
}

module "ci" {
  source = "../../main"

  env                  = var.env
  region               = var.aws_region
  cluster_name         = "bigbang-${var.env}-cluster"
  cluster_version      = var.cluster_version
  ci_pipeline_url      = var.ci_pipeline_url
  vpc_id               = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnets      = data.terraform_remote_state.networking.outputs.private_subnets
  public_subnets       = data.terraform_remote_state.networking.outputs.public_subnets
  #vault_kms_iam_policy = var.vault_kms_iam_policy
  #aws_account_id       = var.aws_account_id
}
