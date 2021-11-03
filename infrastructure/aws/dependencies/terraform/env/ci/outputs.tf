output "vpc_id" {
  value = module.ci.vpc_id
}

output "public_subnets" {
  value = module.ci.public_subnet_ids
}

output "private_subnets" {
  value = module.ci.private_subnet_ids
}