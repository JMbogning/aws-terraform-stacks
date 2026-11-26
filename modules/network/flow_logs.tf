data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region

  flow_logs_bucket_name = "${var.name}-flow-logs-${local.account_id}-${local.region}"

  # Restricts the log delivery service to requests made on behalf of this account.
  log_delivery_conditions = {
    StringEquals = { "aws:SourceAccount" = local.account_id }
    ArnLike      = { "aws:SourceArn" = "arn:${local.partition}:logs:${local.region}:${local.account_id}:*" }
  }
}

resource "aws_kms_key" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  description             = "Encrypts VPC flow logs of ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_in_days

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "FlowLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource  = "*"
        Condition = local.log_delivery_conditions
      },
    ]
  })

  tags = merge(var.tags, { Name = "${var.name}-flow-logs" })
}

resource "aws_kms_alias" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  name          = "alias/${var.name}-flow-logs"
  target_key_id = aws_kms_key.flow_logs[0].key_id
}

# A log bucket does not log its own access: that would need yet another bucket.
#trivy:ignore:AWS-0089
resource "aws_s3_bucket" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket        = local.flow_logs_bucket_name
  force_destroy = var.flow_logs_force_destroy

  tags = merge(var.tags, { Name = local.flow_logs_bucket_name })
}

resource "aws_s3_bucket_ownership_controls" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.flow_logs[0].arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "expire-flow-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.flow_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Rules on noncurrent versions require versioning to be enabled first.
  depends_on = [aws_s3_bucket_versioning.flow_logs]
}

resource "aws_s3_bucket_policy" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "FlowLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.flow_logs[0].arn}/AWSLogs/${local.account_id}/*"
        Condition = merge(local.log_delivery_conditions, {
          StringEquals = merge(local.log_delivery_conditions.StringEquals, { "s3:x-amz-acl" = "bucket-owner-full-control" })
        })
      },
      {
        Sid       = "FlowLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.flow_logs[0].arn
        Condition = local.log_delivery_conditions
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.flow_logs[0].arn,
          "${aws_s3_bucket.flow_logs[0].arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })

  # S3 rejects concurrent changes to the access settings of the same bucket.
  depends_on = [aws_s3_bucket_public_access_block.flow_logs]
}

resource "aws_flow_log" "this" {
  count = var.flow_logs_enabled ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flow_logs[0].arn

  destination_options {
    file_format                = "plain-text"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  tags = merge(var.tags, { Name = "${var.name}-flow-logs" })

  # Without the bucket policy in place, AWS writes its own policy on the bucket, which
  # Terraform would then overwrite on the next apply.
  depends_on = [aws_s3_bucket_policy.flow_logs]
}
