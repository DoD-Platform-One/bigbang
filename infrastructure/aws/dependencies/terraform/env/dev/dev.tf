module "dev" {
  source = "../../main"

  # Set by CI - "TF_VAR_env=$(echo $CI_COMMIT_REF_SLUG | cut -c 1-7)-$(echo $CI_COMMIT_SHA | cut -c 1-7)"
  env = var.env
  # Set by CI - "TF_VAR_ci_pipeline_url=$ci_pipeline_url"
  ci_pipeline_url = var.ci_pipeline_url

  # Calculated in CI
  vpc_cidr = var.vpc_cidr
  hub_vpc_id = var.hub_vpc_id
  hub_tgw = var.hub_tgw
  hub_tgwa = var.hub_tgwa
  hub_tgw_rt = var.hub_tgw_rt
}
