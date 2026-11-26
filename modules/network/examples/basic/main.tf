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

  name               = "example"
  availability_zones = slice(sort(data.aws_availability_zones.available.names), 0, 2)
}
