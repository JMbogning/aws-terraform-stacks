output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.network.private_subnet_ids
}
