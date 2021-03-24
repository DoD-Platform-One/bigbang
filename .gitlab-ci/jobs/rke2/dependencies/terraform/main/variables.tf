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
  # RHEL 8 RKE2 STIG: https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-image-builder
  default = "ami-09d02b6cbe719f221"
}
variable "server_instance_type" {
  default = "m5a.large"
}
variable "servers" {
  default = 1
}
variable "rke2_version" {
  default = "v1.18.12+rke2r2"
}

#
# Generic agent variables
#
variable "agent_ami" {
  # RHEL 8 RKE2 STIG: https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-image-builder
  default = "ami-09d02b6cbe719f221"
}
variable "agent_instance_type" {
  default = "m5a.4xlarge"
}
variable "agent_asg" {
  default = { min : 2, max : 10, desired : 2 }
}
variable "agent_spot" {
  default = false
}

variable "ci_pipeline_url" {
  type        = string
  default     = "none"
  description = "URL to the pipeline that created this resource"
}
