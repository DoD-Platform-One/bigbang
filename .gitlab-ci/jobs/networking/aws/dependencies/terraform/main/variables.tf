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
variable "hub_vpc_id" {
  default = "vpc-5f627a3b"
}

variable "hub_tgw" {
  default = "tgw-0c324b57d019790f4"
}

variable "hub_tgwa" {
  default = "tgw-attach-0dce16098dd33fd2c"
}

variable "hub_tgw_rt" {
  default = "tgw-rtb-04b66987e7d96a3d4"
}

variable ci_pipeline_url {
  type        = string
  default     = "none"
  description = "URL to the pipeline that created this resource"
}
