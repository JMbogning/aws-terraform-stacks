locals {
  # Bucket names are global. The account ID and region make the name unique,
  # and it is never committed: environments read it from backend.hcl (ADR-0003).
  bucket_name = "${var.name}-tfstate-${var.account_id}-${var.region}"
}

resource "aws_kms_key" "state" {
  description             = "Encrypts Terraform state in ${local.bucket_name}"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_in_days
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.name}-tfstate"
  target_key_id = aws_kms_key.state.key_id
}

# Server access logs would need a second bucket for little value here; CloudTrail
# data events are the option when object-level auditing is required.
#trivy:ignore:AWS-0089
resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }

    # One data key per bucket instead of one KMS call per object keeps KMS costs negligible.
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Rules on noncurrent versions require versioning to be enabled first.
  depends_on = [aws_s3_bucket_versioning.state]
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })

  # S3 rejects concurrent changes to the access settings of the same bucket.
  depends_on = [aws_s3_bucket_public_access_block.state]
}
