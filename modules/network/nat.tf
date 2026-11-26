locals {
  # Zones that host a NAT gateway: none, the first zone only, or every zone.
  nat_zones = {
    none   = []
    single = [var.availability_zones[0]]
    per_az = var.availability_zones
  }[var.nat_gateway_mode]
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_zones)

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_zones)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })

  # The gateway needs a working internet gateway to route traffic, which Terraform
  # cannot infer from the arguments above.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat" {
  for_each = var.nat_gateway_mode == "none" ? {} : local.zones

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  # With a single gateway, every zone sends its traffic to the gateway in the first zone.
  nat_gateway_id = aws_nat_gateway.this[var.nat_gateway_mode == "per_az" ? each.key : var.availability_zones[0]].id
}
