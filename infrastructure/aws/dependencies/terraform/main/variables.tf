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
  default = "vpc-02f926e80ce6f13b3"
}
# bigbang-ci
variable "hub_tgw" {
  default = "tgw-074261d87dcb4dc5b"
}
# bigbang-ci
variable "hub_tgwa" {
  default = "tgw-attach-041f22d9e59f73594"
}
# bigbang-ci
variable "hub_tgw_rt" {
  default = "tgw-rtb-0d173269a5c9b598b"
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
