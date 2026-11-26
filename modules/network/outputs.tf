output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, in the order of availability_zones."
  value       = [for zone in var.availability_zones : aws_subnet.public[zone].id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, in the order of availability_zones."
  value       = [for zone in var.availability_zones : aws_subnet.private[zone].id]
}

output "public_route_table_id" {
  description = "ID of the route table shared by the public subnets."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables, one per zone, in the order of availability_zones."
  value       = [for zone in var.availability_zones : aws_route_table.private[zone].id]
}
