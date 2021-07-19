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
  default = false
  description = "Toggle dependency downloading"
}

#
# Server variables
#
variable "server_ami" {
  # RHEL 8.3 RKE2 v1.20.7+rke2r2 STIG: https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-image-builder
  default = "ami-04fc9486a0c1633cb"
}
variable "server_instance_type" {
  default = "m5a.2xlarge"
}
variable "servers" {
  default = 1
}
variable "rke2_version" {
  default = "v1.20.5+rke2r1"
}

#
# Generic agent variables
#
variable "agent_ami" {
  # RHEL 8.3 RKE2 v1.20.7+rke2r2 STIG: https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-image-builder
  default = "ami-04fc9486a0c1633cb"
}
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
