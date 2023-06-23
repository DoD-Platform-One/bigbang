variable "region" {}
variable "env" {}
variable "organization" {
  default = "bigbang"
}
#variable "tags" {}

variable "main_cidr" {
  default = "10.10.0.0/16"
}

variable "k8s_version" {
  default = "1.21"
}

variable "public_access_cidrs" {
  description = "CIDR ranges of IPs allowed to access K8s endpoints, etc"
  type        = list(string)
  default     = []
}

variable "policy_arn_prefix" {
  default = "aws-us-gov"
  description = "gov cloud will have aws-us-gov"
}

variable "cluster_name" {
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

variable "cluster_instance_types" {
  type    = list(string)
  default = ["m5a.4xlarge"]
}

variable "vpc_id" {}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ci_pipeline_url" {
  type        = string
  default     = "none"
  description = "URL to the pipeline that created this resource"
}

variable "iam_instance_profile" {
  default = "InstanceOpsRole"
}
