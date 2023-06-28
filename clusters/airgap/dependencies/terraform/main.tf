provider "aws" {
  region = "us-gov-west-1"
}

terraform {
  backend "s3" {
    bucket               = "airgap-tf-states"
    key                  = "terraform.tfstate"
    region               = "us-gov-west-1"
    dynamodb_table       = "airgap-tf-states-lock"
    workspace_key_prefix = "airgap"
    encrypt              = true
  }
}

locals {
  #selects a random subnet from filtered ids
  subnet_ids_list         = tolist(data.aws_subnets.ci_subnets.ids)
  subnet_ids_random_index = random_id.index.dec % length(data.aws_subnets.ci_subnets.ids)
  random_subnet_id        = local.subnet_ids_list[local.subnet_ids_random_index]
}

resource "random_id" "index" {
  byte_length = 4
}

resource "aws_instance" "bb-ci-airgap" {
  ami                    = data.aws_ami.airgap_ami.id
  instance_type          = "m5.2xlarge"
  subnet_id              = local.random_subnet_id
  vpc_security_group_ids = [aws_security_group.airgap_sg.id]
  iam_instance_profile   = "airgap_ci_role"
  key_name               = var.env
  root_block_device {
    volume_size           = "100"
    delete_on_termination = true
  }
  tags = {
    Name            = var.airgap_env_name
    ci_pipeline_url = var.ci_pipeline_url
    ci_pipeline_id  = var.ci_pipeline_id
    env             = var.env
  }
  user_data = templatefile("templates/user_data.tftpl", {
    zarf_version = var.zarf_version
    env          = var.env
  })
}

data "aws_ami" "airgap_ami" {
  most_recent = true
  owners      = ["345084742485"]
  filter {
    name   = "name"
    values = ["CIS Red Hat Enterprise Linux 7 STIG Benchmark*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "ci_vpc" {
  filter {
    name   = "tag:Name"
    values = ["bigbang-ci-cluster-vpc"]
  }
}

data "aws_subnets" "ci_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ci_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["bigbang-ci-cluster-private*"]
  }
}

resource "aws_security_group" "airgap_sg" {
  name        = var.airgap_env_name
  description = "Allow CI communication only"
  vpc_id      = data.aws_vpc.ci_vpc.id

  tags = {
    Name            = var.airgap_env_name
    ci_pipeline_url = var.ci_pipeline_url
    ci_pipeline_id  = var.ci_pipeline_id
    env             = var.env
  }
}

resource "aws_security_group_rule" "airgap_allow_ingress_ci" {
  description       = "restricted to ci"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.ci_vpc.cidr_block]
  security_group_id = aws_security_group.airgap_sg.id
}

resource "aws_security_group_rule" "airgap_allow_egress_ci" {
  description       = "restricted to ci"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.ci_vpc.cidr_block]
  security_group_id = aws_security_group.airgap_sg.id
}

resource "aws_security_group_rule" "airgap_allow_egress_s3" {
  description       = "permit s3"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.s3_prefix.id]
  security_group_id = aws_security_group.airgap_sg.id
}

resource "aws_security_group_rule" "internet_access" {
  description       = "internet access"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.airgap_sg.id
}

data "aws_ec2_managed_prefix_list" "s3_prefix" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.us-gov-west-1.s3"]
  }
}
