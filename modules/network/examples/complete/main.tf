provider "aws" {
  region = var.region
}

# Local Zones and Wavelength Zones require an opt-in and are left out.
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "network" {
  source = "../.."

  name                     = "example-complete"
  cidr_block               = "10.20.0.0/16"
  availability_zones       = slice(sort(data.aws_availability_zones.available.names), 0, 3)
  nat_gateway_mode         = "per_az"
  enable_ipv6              = true
  interface_endpoints      = ["ssm", "ssmmessages", "ec2messages", "logs"]
  flow_logs_retention_days = 90

  tags = {
    DataClassification = "internal"
  }
}
