variable "account_id" {
  description = "ID of the AWS account of this environment. Set it in local.auto.tfvars, which is not committed."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}
