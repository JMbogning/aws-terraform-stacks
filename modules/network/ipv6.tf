resource "aws_route" "public_internet_ipv6" {
  count = var.enable_ipv6 ? 1 : 0

  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

# Outbound-only IPv6 access for private subnets. Unlike a NAT gateway it has no hourly
# charge, so services that support IPv6 can be reached without paying for NAT.
resource "aws_egress_only_internet_gateway" "this" {
  count = var.enable_ipv6 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-eigw" })
}

resource "aws_route" "private_ipv6_egress" {
  for_each = var.enable_ipv6 ? local.zones : {}

  route_table_id              = aws_route_table.private[each.key].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this[0].id
}
