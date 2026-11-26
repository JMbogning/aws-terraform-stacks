# bucket, region and kms_key_id come from backend.hcl at the repository root (ADR-0003).
terraform {
  backend "s3" {
    key          = "dev/network/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
