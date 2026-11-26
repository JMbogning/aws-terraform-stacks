# Local Zones and Wavelength Zones require an opt-in and are left out.
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "network" {
  source = "../../../modules/network"

  name               = "ats-prod"
  cidr_block         = "10.1.0.0/16"
  availability_zones = slice(sort(data.aws_availability_zones.available.names), 0, 3)

  # Each zone keeps outbound access if another zone fails (ADR-0004).
  nat_gateway_mode = "per_az"

  flow_logs_retention_days = 365
}

# Other stacks read these values instead of this state (see docs/conventions.md).
resource "aws_ssm_parameter" "outputs" {
  for_each = {
    "vpc-id"             = module.network.vpc_id
    "public-subnet-ids"  = join(",", module.network.public_subnet_ids)
    "private-subnet-ids" = join(",", module.network.private_subnet_ids)
  }

  name  = "/ats/prod/network/${each.key}"
  type  = "String"
  value = each.value
}
