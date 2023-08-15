variable "aws_region" {
  default = "us-gov-west-1"
}
variable "env" {}
variable "ci_pipeline_url" {}
variable "cluster_name" {
  default = "bigbang-eks-cluster"
}

variable "aws_account_id" {}

variable "cluster_version" {
  default = "1.26"
}

variable "vault_kms_iam_policy" {
  default = "EKS-Pipeline-Vault-KMS-Access"
}

variable "ng_desired_size" {
  type    = number
  default = "3"
}

variable "ng_max_size" {
  type    = number
  default = "5"
}

variable "ng_min_size" {
  type    = number
  default = "3"
}
