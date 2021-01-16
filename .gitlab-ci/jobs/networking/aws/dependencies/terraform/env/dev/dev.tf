terraform {
  backend "s3" {
    bucket               = "umbrella-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    dynamodb_table       = "umbrella-tf-states-lock"
    workspace_key_prefix = "aws-networking"
  }
}
module "dev" {
  source   = "../../main"
  env      = "dev"
  vpc_cidr = "10.255.0.0/16"
}
