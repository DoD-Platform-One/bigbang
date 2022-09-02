variable "env" {}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR"
  type        = string
}

variable "aws_region" {
  type    = string
  default = "us-gov-west-1"
}

#
# Spoke variables
# We can hardcode these for now... they haven't changed in 8 months
#
# bigbang-ci
variable "hub_vpc_id" {
  default = "vpc-020f0e0729b49b801"
}
# bigbang-ci
variable "hub_tgw" {
  default = "tgw-096a10016de907333"
}
# bigbang-ci
variable "hub_tgwa" {
  default = "tgw-attach-03f9f94341e9a4206"
}
# bigbang-ci
variable "hub_tgw_rt" {
  default = "tgw-rtb-09ad4afa5e4faa2cb"
}

variable "ci_pipeline_url" {
  type        = string
  default     = "none"
  description = "URL to the pipeline that created this resource"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to attach to all resources created"
  default     = {}
}
