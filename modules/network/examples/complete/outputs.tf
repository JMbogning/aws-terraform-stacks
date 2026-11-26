output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.network.private_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Public IPv4 addresses of the NAT gateways."
  value       = module.network.nat_gateway_public_ips
}

output "vpc_ipv6_cidr_block" {
  description = "IPv6 CIDR block of the VPC."
  value       = module.network.vpc_ipv6_cidr_block
}
