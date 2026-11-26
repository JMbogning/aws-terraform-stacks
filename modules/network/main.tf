locals {
  # Subnets are keyed by zone rather than by position, so adding a zone does not
  # renumber the existing ones.
  zones = { for index, zone in var.availability_zones : zone => index }

  # Each subnet is a sixteenth of the VPC. Public subnets take the first blocks and
  # private subnets start at the ninth, which leaves room for more zones in both tiers.
  public_cidrs  = { for zone, index in local.zones : zone => cidrsubnet(var.cidr_block, 4, index) }
  private_cidrs = { for zone, index in local.zones : zone => cidrsubnet(var.cidr_block, 4, index + 8) }
}

resource "aws_vpc" "this" {
  cidr_block                       = var.cidr_block
  assign_generated_ipv6_cidr_block = var.enable_ipv6
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

# Takes over the default security group and removes its rules, so that a resource
# launched without an explicit group gets no network access.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-default-deny-all" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  for_each = local.zones

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = local.public_cidrs[each.key]

  # The /56 assigned to the VPC is split into /64s, at the same positions as the IPv4 blocks.
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, local.zones[each.key]) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(var.tags, { Name = "${var.name}-public-${each.key}", Tier = "public" })
}

resource "aws_subnet" "private" {
  for_each = local.zones

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = local.private_cidrs[each.key]

  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, local.zones[each.key] + 8) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(var.tags, { Name = "${var.name}-private-${each.key}", Tier = "private" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public_internet_ipv4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# One table per zone, so that each zone can later use the NAT gateway in its own zone.
resource "aws_route_table" "private" {
  for_each = local.zones

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-private-${each.key}" })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
