terraform {
  backend "s3" {
    bucket               = "umbrella-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    dynamodb_table       = "umbrella-tf-states-lock"
    workspace_key_prefix = "aws-networking"
  }
}

module "ci" {
  source = "../../main"

  # Set by CI - "${CI_COMMIT_REF_SLUG}-${CI_COMMIT_SHORT_SHA}"
  env = var.env

  # Calculated in CI
  vpc_cidr = var.vpc_cidr
}
