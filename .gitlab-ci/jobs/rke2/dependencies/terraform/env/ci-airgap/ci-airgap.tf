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

  env     = var.env
  vpc_id  = data.terraform_remote_state.networking.outputs.vpc_id
  subnets = data.terraform_remote_state.networking.outputs.intra_subnets

  download   = false
  server_ami = "ami-00aab2121681e4a31"
  agent_ami  = "ami-00aab2121681e4a31"
}