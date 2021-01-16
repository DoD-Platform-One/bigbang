terraform {
  backend "s3" {
    bucket               = "umbrella-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    dynamodb_table       = "umbrella-tf-states-lock"
    workspace_key_prefix = "rke2"
  }
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket               = "umbrella-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    workspace_key_prefix = "aws-networking"
  }
  workspace = var.env
}

module "ci" {
  source = "../../main"

  env             = var.env
  ci_pipeline_url = var.ci_pipeline_url
  vpc_id          = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnets = data.terraform_remote_state.networking.outputs.private_subnets
  public_subnets  = data.terraform_remote_state.networking.outputs.public_subnets
}