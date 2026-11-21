variable "account_id" {
  description = "ID of the AWS account that holds the state. Set it in local.auto.tfvars, which is not committed."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "region" {
  description = "Region of the state bucket."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.region))
    error_message = "region must be an AWS region code, for example us-east-1."
  }
}

variable "name" {
  description = "Prefix of every resource name."
  type        = string
  default     = "ats"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name))
    error_message = "name must start with a lowercase letter and contain 2 to 20 lowercase letters, digits or hyphens."
  }
}

variable "noncurrent_version_retention_days" {
  description = "Number of days a previous version of a state file is kept before it is deleted."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_retention_days >= 1
    error_message = "noncurrent_version_retention_days must be at least 1."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period, in days, before the KMS key is deleted after a destroy."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}

variable "force_destroy" {
  description = "Allow destroy to delete the bucket while it still contains state files. Enable only to tear down a test deployment."
  type        = bool
  default     = false
}
