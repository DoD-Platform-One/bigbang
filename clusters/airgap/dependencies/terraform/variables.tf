variable "ci_pipeline_url" {
  type        = string
  default     = "ci_pipeline_url"
}

variable "ci_pipeline_id" {
  type        = string
  default     = "ci_pipeline_id"
}

variable "airgap_env_name" {
  type        = string
  default     = "airgap_env_name"
}

variable "bb_release" {}

variable "zarf_version" {
  type = string
  default = "v0.27.0"
}

variable "env" {}