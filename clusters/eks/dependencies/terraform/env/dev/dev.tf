provider "aws" {
  region = "us-gov-west-1"
}

data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../../../../../../infrastructure/aws/dependencies/terraform/env/dev/terraform.tfstate"
  }
}

module "dev" {
  source = "../../main"

  env             = var.env
  region          = var.aws_region
  cluster_name    = "bigbang-${var.env}-cluster"
  k8s_version     = var.k8s_version
  ci_pipeline_url = var.ci_pipeline_url
  vpc_id              = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnets     = data.terraform_remote_state.networking.outputs.private_subnets
  public_subnets      = data.terraform_remote_state.networking.outputs.public_subnets
}
