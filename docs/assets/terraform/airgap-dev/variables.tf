
# Provider id based on Mesosphere account information
variable "profile_id" {
  description = ""
  # Default region is default
  default = "default"
}

# AWS Region id
variable "region_id" {
  description = ""
  # Default region is us-gov-west-1
  default = "us-gov-west-1"
}

# Cluster UUID
resource "random_string" "random" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

# Cluster id
variable "cluster_id" {
  description = ""
  # Default region is airgap-????
  default = "airgap-"
}

# ec2.tf
variable "image_id" {
  description = "Amazon AWS AMI"
  # default     = "ami-06eeaf749779ed329"
  default = "ami-06eeaf749779ed329"
}

# ec2.tf
variable "image_username" {
  description = "Amazon AWS AMI username"
  default     = "centos"
}

# ec2.tf
variable "ec2_instance_type" {
  description = "AWS EC2 Instance type"
  # Default instance type m5.xlarge
  default = "m5.xlarge"
}

# Ssh keyname
variable "ssh_key_name" {
  description = ""
  # Comment
  default = "airgap"
}

# Cluster owner
#variable "owner" {
#    description = "Owner of the cluster"
#    # Comment
#    default      = "egoode"
#}

