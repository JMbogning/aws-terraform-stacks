mock_provider "aws" {}

variables {
  account_id = "111111111111"
}

run "secure_defaults" {
  assert {
    condition     = aws_s3_bucket.state.bucket == "ats-tfstate-111111111111-us-east-1"
    error_message = "The bucket name must combine the prefix, the account ID and the region."
  }

  assert {
    condition     = !aws_s3_bucket.state.force_destroy
    error_message = "A bucket that still holds state must not be deletable by default."
  }

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled to recover previous state files."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.state.block_public_acls,
      aws_s3_bucket_public_access_block.state.block_public_policy,
      aws_s3_bucket_public_access_block.state.ignore_public_acls,
      aws_s3_bucket_public_access_block.state.restrict_public_buckets,
    ])
    error_message = "All four public access block settings must be enabled."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.state.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "State files must be encrypted with the KMS key."
  }

  assert {
    condition     = aws_kms_key.state.enable_key_rotation
    error_message = "Automatic KMS key rotation must be enabled."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.state.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "The bucket policy must deny requests that do not use TLS."
  }
}

run "rejects_invalid_account_id" {
  command = plan

  variables {
    account_id = "12345"
  }

  expect_failures = [var.account_id]
}

run "rejects_invalid_name" {
  command = plan

  variables {
    name = "Invalid_Name"
  }

  expect_failures = [var.name]
}
