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

  name               = "ats-dev"
  cidr_block         = "10.0.0.0/16"
  availability_zones = slice(sort(data.aws_availability_zones.available.names), 0, 2)

  # An idle development network should cost nothing: no NAT gateway (ADR-0004).
  nat_gateway_mode = "none"

  # Development logs are disposable, so a destroy may delete them.
  flow_logs_retention_days    = 14
  flow_logs_force_destroy     = true
  kms_deletion_window_in_days = 7
}

# Other stacks read these values instead of this state (see docs/conventions.md).
resource "aws_ssm_parameter" "outputs" {
  for_each = {
    "vpc-id"             = module.network.vpc_id
    "public-subnet-ids"  = join(",", module.network.public_subnet_ids)
    "private-subnet-ids" = join(",", module.network.private_subnet_ids)
  }

  name  = "/ats/dev/network/${each.key}"
  type  = "String"
  value = each.value
}
