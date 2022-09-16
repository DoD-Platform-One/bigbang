# Locals
locals {
  az = format("%s%s", var.region_id, "a")
}

# Provider
provider "aws" {
  profile = var.profile_id
  region  = var.region_id
}

# Vpc
resource "aws_vpc" "airgap_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_id}-${random_string.random.result}-vpc"
  }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.airgap_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = local.az

  tags = {
    Name = "airgap-public-subnet"
  }
}

# Igw
resource "aws_internet_gateway" "airgap_vpc_igw" {
  vpc_id = aws_vpc.airgap_vpc.id

  tags = {
    Name = "airgap-igw"
  }
}

# Public route table
resource "aws_route_table" "airgap_vpc_region_public" {
  vpc_id = aws_vpc.airgap_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airgap_vpc_igw.id
  }

  tags = {
    Name = "airgap-public-rt"
  }
}

# Public route table associations
resource "aws_route_table_association" "airgap_vpc_region_public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.airgap_vpc_region_public.id
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.airgap_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = local.az

  tags = {
    Name = "airgap-private-subnet"
  }
}

# Private routing table
resource "aws_route_table" "airgap_vpc_region_private" {
  vpc_id = aws_vpc.airgap_vpc.id

  tags = {
    Name = "airgap-private-rt"
  }
}

# Private routing table association
resource "aws_route_table_association" "airgap_vpc_region_private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.airgap_vpc_region_private.id
}

# Output
#output "connection_details" {
#  value = <<EOF

#    Use the following to connect to the bootstrap node and enjoy the ride...

#   ssh -J ${var.image_username}@${aws_instance.staging_instance.public_ip} ${var.image_username}@${aws_instance.bootstrap_instance.private_ip}

#  EOF
#}

#output "public_ip" {
#  description = "List of public IP addresses assigned to the instances, if applicable"
#  value       = "${aws_instance.staging_instance.*.public_ip}"
#}

#output "private_ip" {
#  description = "List of private IP addresses assigned to the instances, if applicable"
#  value       = "${aws_instance.bootstrap_instance.*.private_ip}"
#}

output "follow_up" {
  value = <<EOF
    
    Nothing to see here but I have finished.

    EOF
}
