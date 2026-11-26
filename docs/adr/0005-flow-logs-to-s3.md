# 0005. VPC flow logs to S3

- Status: Accepted
- Date: 2026-11-26

## Context

Flow logs record the metadata of every connection in a VPC: source, destination, port and whether it was accepted. They are needed to investigate incidents and are required by most security baselines.

They can be delivered to CloudWatch Logs or to S3. CloudWatch Logs needs an IAM role for delivery and charges about twice as much per gigabyte ingested. S3 needs no role, stores logs cheaply and can be queried with Athena.

## Decision

- The network module creates one bucket per VPC and delivers flow logs to it in plain text, with Hive-compatible hourly partitions so that Athena can query them without preprocessing.
- The bucket is encrypted with a dedicated KMS key, versioned, blocked from public access and reachable over TLS only. Logs expire after `flow_logs_retention_days`, 30 by default.
- The bucket and key policies only accept the log delivery service when it acts for this account (`aws:SourceAccount` and `aws:SourceArn` conditions).
- Flow logs are on by default and can be turned off with `flow_logs_enabled`.

## Consequences

- No IAM role is created, so the network stack needs no IAM permissions.
- Each environment pays about $1 per month for its KMS key, plus delivery and storage of its logs.
- Logs are read with Athena or by downloading files, not with CloudWatch Logs Insights.
- The log bucket does not record its own access logs, which would need yet another bucket.
- Rejected: CloudWatch Logs, for the IAM role and the higher price; a central log archive bucket, which belongs in a multi-account setup with a dedicated logging account.
