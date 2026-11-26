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

variable "nat_gateway_mode" {
  description = "Outbound IPv4 internet access for private subnets: none, single (one gateway shared by every zone) or per_az (one gateway in each zone). See ADR-0004."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be none, single or per_az."
  }
}

variable "enable_ipv6" {
  description = "Assign an Amazon-provided IPv6 block to the VPC and a /64 to every subnet. Private subnets reach the internet over IPv6 through an egress-only gateway, which has no hourly charge."
  type        = bool
  default     = false
}

variable "gateway_endpoints" {
  description = "Services reached from private subnets through gateway endpoints, which are free."
  type        = set(string)
  default     = ["s3", "dynamodb"]

  validation {
    condition     = alltrue([for service in var.gateway_endpoints : contains(["s3", "dynamodb"], service)])
    error_message = "gateway_endpoints only supports s3 and dynamodb."
  }
}

variable "interface_endpoints" {
  description = "Services reached from private subnets through interface endpoints, for example [\"ssm\", \"logs\"]. Each one costs about $0.01 per hour per availability zone."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for service in var.interface_endpoints : can(regex("^[a-z0-9.-]+$", service))])
    error_message = "interface_endpoints must contain service names such as ssm, logs or ecr.api."
  }
}

variable "flow_logs_enabled" {
  description = "Record the metadata of all traffic in the VPC to a dedicated, encrypted S3 bucket. See ADR-0005."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Number of days flow log files are kept."
  type        = number
  default     = 30

  validation {
    condition     = var.flow_logs_retention_days >= 1
    error_message = "flow_logs_retention_days must be at least 1."
  }
}

variable "flow_logs_force_destroy" {
  description = "Allow destroy to delete the flow log bucket while it still contains logs. Enable only for disposable environments."
  type        = bool
  default     = false
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period, in days, before the flow log KMS key is deleted after a destroy."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}
