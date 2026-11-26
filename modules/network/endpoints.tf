data "aws_region" "current" {}

# S3 and DynamoDB traffic from private subnets stays on the AWS network and does not
# go through a NAT gateway, where it would be charged per gigabyte.
resource "aws_vpc_endpoint" "gateway" {
  for_each = var.gateway_endpoints

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for zone in var.availability_zones : aws_route_table.private[zone].id]

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_security_group" "endpoints" {
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  name        = "${var.name}-vpc-endpoints"
  description = "HTTPS from the VPC to interface endpoints"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-vpc-endpoints" })
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  security_group_id = aws_security_group.endpoints[0].id
  description       = "HTTPS from the VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = aws_vpc.this.cidr_block
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for zone in var.availability_zones : aws_subnet.private[zone].id]
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}
