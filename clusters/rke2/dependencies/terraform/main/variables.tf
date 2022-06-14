variable "env" {}
variable "aws_region" {
  default = "us-gov-west-1"
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

#
# Cluster variables
#
variable "controlplane_internal" {
  default = true
}

variable "enable_ccm" {
  default = true
}

variable "enable_autoscaler" {
  default = true
}

variable "ssh_authorized_keys" {
  type    = list(string)
  default = []
}

variable "download" {
  type    = bool
  default = true
  description = "Toggle dependency downloading"
}

#
# Server variables
#
variable "server_instance_type" {
  default = "m5a.2xlarge"
}
variable "servers" {
  default = 1
}
variable "rke2_version" {
  default = "v1.23.5+rke2r1"
}

variable "rke2_config" {
  type = string
  default = <<EOF
disable:
  - rke2-ingress-nginx
EOF
}

variable "iam_instance_profile" {
  default = "InstanceOpsRole"
}

#
# Generic agent variables
#
variable "agent_instance_type" {
  default = "m5a.4xlarge"
}
variable "agent_asg" {
  default = { min : 3, max : 10, desired : 3 }
}
variable "agent_spot" {
  default = true
}

variable "ci_pipeline_url" {
  type        = string
  default     = "none"
  description = "URL to the pipeline that created this resource"
}
