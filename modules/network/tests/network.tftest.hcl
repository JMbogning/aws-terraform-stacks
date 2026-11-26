mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }

  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }

  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }

  # Values the real API would return, needed by expressions evaluated after apply.
  mock_resource "aws_vpc" {
    defaults = { ipv6_cidr_block = "2600:1f18:1234:5600::/56" }
  }

  mock_resource "aws_s3_bucket" {
    defaults = { arn = "arn:aws:s3:::test-flow-logs" }
  }

  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-1:111111111111:key/00000000-0000-0000-0000-000000000000" }
  }
}

variables {
  name               = "test"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

run "default_layout" {
  command = plan

  assert {
    condition     = [for zone in var.availability_zones : aws_subnet.public[zone].cidr_block] == ["10.0.0.0/20", "10.0.16.0/20"]
    error_message = "Public subnets must take the first blocks of the VPC."
  }

  assert {
    condition     = [for zone in var.availability_zones : aws_subnet.private[zone].cidr_block] == ["10.0.128.0/20", "10.0.144.0/20"]
    error_message = "Private subnets must start at the ninth block of the VPC."
  }

  assert {
    condition     = alltrue([for subnet in aws_subnet.public : subnet.map_public_ip_on_launch != true])
    error_message = "Public subnets must not assign public IPv4 addresses automatically."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat) == 0
    error_message = "No NAT gateway must be created by default."
  }

  assert {
    condition     = length(aws_egress_only_internet_gateway.this) == 0 && output.vpc_ipv6_cidr_block == null
    error_message = "IPv6 must be disabled by default."
  }

  assert {
    condition     = keys(aws_vpc_endpoint.gateway) == ["dynamodb", "s3"] && aws_vpc_endpoint.gateway["s3"].service_name == "com.amazonaws.us-east-1.s3"
    error_message = "The free S3 and DynamoDB gateway endpoints must be created by default."
  }

  assert {
    condition     = length(aws_vpc_endpoint.interface) == 0 && output.endpoints_security_group_id == null
    error_message = "No interface endpoint must be created by default."
  }

  assert {
    condition     = length(aws_flow_log.this) == 1 && aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow logs must record all traffic by default."
  }
}

run "single_nat_gateway" {
  command = plan

  variables {
    nat_gateway_mode = "single"
  }

  assert {
    condition     = keys(aws_nat_gateway.this) == ["us-east-1a"]
    error_message = "A single NAT gateway must be created in the first zone."
  }

  assert {
    condition     = length(aws_route.private_nat) == 2
    error_message = "Every private route table must send IPv4 internet traffic to the NAT gateway."
  }
}

run "nat_gateway_per_zone" {
  command = plan

  variables {
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    nat_gateway_mode   = "per_az"
  }

  assert {
    condition     = keys(aws_nat_gateway.this) == ["us-east-1a", "us-east-1b", "us-east-1c"]
    error_message = "One NAT gateway must be created in each zone."
  }

  assert {
    condition     = length(aws_route.private_nat) == 3
    error_message = "Each private route table must use a NAT gateway."
  }
}

run "ipv6" {
  variables {
    enable_ipv6 = true
  }

  assert {
    condition     = aws_subnet.public["us-east-1a"].ipv6_cidr_block == "2600:1f18:1234:5600::/64" && aws_subnet.private["us-east-1b"].ipv6_cidr_block == "2600:1f18:1234:5609::/64"
    error_message = "Subnets must get the /64 at the same position as their IPv4 block."
  }

  assert {
    condition     = length(aws_route.public_internet_ipv6) == 1 && length(aws_route.private_ipv6_egress) == 2
    error_message = "Public subnets must reach the internet gateway and private subnets the egress-only gateway over IPv6."
  }
}

run "interface_endpoints" {
  command = plan

  variables {
    interface_endpoints = ["ssm", "logs"]
  }

  assert {
    condition     = keys(aws_vpc_endpoint.interface) == ["logs", "ssm"] && alltrue([for endpoint in aws_vpc_endpoint.interface : endpoint.private_dns_enabled])
    error_message = "Interface endpoints must be created with private DNS."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.endpoints_https[0].from_port == 443 && aws_vpc_security_group_ingress_rule.endpoints_https[0].cidr_ipv4 == "10.0.0.0/16"
    error_message = "Interface endpoints must accept HTTPS from the VPC only."
  }
}

run "flow_log_storage" {
  assert {
    condition     = aws_s3_bucket.flow_logs[0].bucket == "test-flow-logs-111111111111-us-east-1" && !aws_s3_bucket.flow_logs[0].force_destroy
    error_message = "The flow log bucket must be named after the account and region, and protected from deletion."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.flow_logs[0].rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms" && aws_kms_key.flow_logs[0].enable_key_rotation
    error_message = "Flow logs must be encrypted with a rotated KMS key."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.flow_logs[0].policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "111111111111"
    error_message = "Only log deliveries made for this account may write to the bucket."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.flow_logs[0].policy).Statement[2].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "The bucket policy must deny requests that do not use TLS."
  }
}

run "flow_logs_disabled" {
  command = plan

  variables {
    flow_logs_enabled = false
  }

  assert {
    condition     = length(aws_flow_log.this) == 0 && length(aws_s3_bucket.flow_logs) == 0 && length(aws_kms_key.flow_logs) == 0
    error_message = "Disabling flow logs must remove the bucket and the key."
  }
}

run "rejects_cidr_outside_range" {
  command = plan

  variables {
    cidr_block = "10.0.0.0/8"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_cidr_with_host_bits" {
  command = plan

  variables {
    cidr_block = "10.0.1.0/16"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_single_zone" {
  command = plan

  variables {
    availability_zones = ["us-east-1a"]
  }

  expect_failures = [var.availability_zones]
}

run "rejects_duplicate_zones" {
  command = plan

  variables {
    availability_zones = ["us-east-1a", "us-east-1a"]
  }

  expect_failures = [var.availability_zones]
}

run "rejects_unknown_nat_mode" {
  command = plan

  variables {
    nat_gateway_mode = "two"
  }

  expect_failures = [var.nat_gateway_mode]
}

run "rejects_unsupported_gateway_endpoint" {
  command = plan

  variables {
    gateway_endpoints = ["ssm"]
  }

  expect_failures = [var.gateway_endpoints]
}
