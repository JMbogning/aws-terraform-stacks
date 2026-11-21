# 0003. State backend configuration

- Status: Accepted
- Date: 2026-11-21

## Context

Every environment stores its state in the S3 bucket created by `bootstrap/state-backend`. A `backend` block cannot read variables, so the bucket name would normally be written in each environment directory.

The repository is public. Bucket names are global, and a unique name built from the account ID would publish that ID. A fixed name would also send anyone who reuses the code to a bucket they do not own.

Since Terraform 1.10, the S3 backend can lock state with a lock file in the same bucket. A DynamoDB table is no longer needed.

## Decision

- One state bucket per account, named `<name>-tfstate-<account_id>-<region>` and encrypted with a customer managed KMS key.
- Environments use a partial backend configuration. The committed `backend` block holds only the values that do not identify the account:

  ```hcl
  terraform {
    backend "s3" {
      key          = "dev/network/terraform.tfstate"
      encrypt      = true
      use_lockfile = true
    }
  }
  ```

- `bucket`, `region` and `kms_key_id` come from `backend.hcl` at the repository root. It is generated from the `backend_config` output of the bootstrap, is not committed, and `scripts/stack.sh` passes it to `terraform init`.
- `kms_key_id` is always set: with `encrypt = true` and no key, the backend requests S3-managed encryption instead of the bucket's KMS key.

## Consequences

- The repository contains no account ID, bucket name or key ARN. Anyone reusing it runs the bootstrap in their own account and gets their own `backend.hcl`.
- Each workstation needs `backend.hcl` before its first `terraform init`. Generating it takes one command.
- Rejected: writing the bucket name in each `backend` block, which publishes the account ID; a committed name with a random suffix, which still points other users to a bucket they do not own; a DynamoDB lock table, which adds a resource that native locking makes unnecessary.
