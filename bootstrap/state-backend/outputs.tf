output "bucket_name" {
  description = "Name of the state bucket."
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key that encrypts state files."
  value       = aws_kms_key.state.arn
}

output "backend_config" {
  description = "Partial backend configuration for environments. Save it as backend.hcl at the repository root, which is not committed."
  value       = <<-EOT
    bucket     = "${aws_s3_bucket.state.id}"
    region     = "${var.region}"
    kms_key_id = "${aws_kms_key.state.arn}"
  EOT
}
