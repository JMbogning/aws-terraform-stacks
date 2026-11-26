variable "name" {
  description = "Prefix of every resource name, for example ats-dev."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name))
    error_message = "name must start with a lowercase letter and contain 2 to 20 lowercase letters, digits or hyphens."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR block of the VPC, between /16 and /20. Each subnet takes a sixteenth of it."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("^[0-9.]+/(1[6-9]|20)$", var.cidr_block)) && try(cidrsubnet(var.cidr_block, 0, 0) == var.cidr_block, false)
    error_message = "cidr_block must be an IPv4 network address with a prefix length between /16 and /20, for example 10.0.0.0/16."
  }
}

variable "availability_zones" {
  description = "Availability zones that receive one public and one private subnet each, for example [\"us-east-1a\", \"us-east-1b\"]."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 4 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "availability_zones must list 2 to 4 distinct zones."
  }
}

variable "tags" {
  description = "Tags added to every resource, on top of the provider default tags."
  type        = map(string)
  default     = {}
}
