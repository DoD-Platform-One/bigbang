variable "env" {}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR"
  type        = string
  default = "10.21.0.0/16"

}

variable "aws_region" {
  type    = string
  default = "us-gov-west-1"
}
#
# Spoke variables
# We can hardcode these for now...
#
# bigbang Dogfood
variable "hub_vpc_id" {
  default = "vpc-01f15705d60b5ddb6"
}
# bigbang dogfood
variable "hub_tgw" {
  default = "tgw-07b12bb637ef35dba"
}
# bigbang-ci
variable "hub_tgwa" {
  default = "tgw-attach-0e98e434199b55ea9"
}
# bigbang-ci
variable "hub_tgw_rt" {
  default = "tgw-rtb-03abfd8985981dd93"
}

variable "ci_pipeline_url" {
  type        = string
  default     = "none"
  description = "URL to the pipeline that created this resource"
}

#variable "common_tags" {
#  type        = map(string)
#  description = "Common tags to attach to all resources created"
#  default     = {}
#}
