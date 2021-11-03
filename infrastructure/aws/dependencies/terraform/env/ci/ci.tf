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

  # Set by CI - "TF_VAR_env=$(echo $CI_COMMIT_REF_SLUG | cut -c 1-7)-$(echo $CI_COMMIT_SHA | cut -c 1-7)"
  env = var.env
  # Set by CI - "TF_VAR_ci_pipeline_url=$ci_pipeline_url"
  ci_pipeline_url = var.ci_pipeline_url

  # Calculated in CI
  vpc_cidr = var.vpc_cidr
}
