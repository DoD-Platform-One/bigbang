output "vpc_id" {
  value = module.dev.vpc_id
}

output "public_subnets" {
  value = module.dev.public_subnet_ids
}

output "private_subnets" {
  value = module.dev.private_subnet_ids
}