# Network

Multi-AZ VPC with one public and one private subnet per availability zone.

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.17 |
| aws | >= 6.0 |

### Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_egress_only_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/egress_only_internet_gateway) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_kms_alias.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_ipv6_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_security_group_ingress_rule.endpoints_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| availability\_zones | Availability zones that receive one public and one private subnet each, for example ["us-east-1a", "us-east-1b"]. | `list(string)` | n/a | yes |
| name | Prefix of every resource name, for example ats-dev. | `string` | n/a | yes |
| cidr\_block | IPv4 CIDR block of the VPC, between /16 and /20. Each subnet takes a sixteenth of it. | `string` | `"10.0.0.0/16"` | no |
| enable\_ipv6 | Assign an Amazon-provided IPv6 block to the VPC and a /64 to every subnet. Private subnets reach the internet over IPv6 through an egress-only gateway, which has no hourly charge. | `bool` | `false` | no |
| flow\_logs\_enabled | Record the metadata of all traffic in the VPC to a dedicated, encrypted S3 bucket. See ADR-0005. | `bool` | `true` | no |
| flow\_logs\_force\_destroy | Allow destroy to delete the flow log bucket while it still contains logs. Enable only for disposable environments. | `bool` | `false` | no |
| flow\_logs\_retention\_days | Number of days flow log files are kept. | `number` | `30` | no |
| gateway\_endpoints | Services reached from private subnets through gateway endpoints, which are free. | `set(string)` | ```[ "s3", "dynamodb" ]``` | no |
| interface\_endpoints | Services reached from private subnets through interface endpoints, for example ["ssm", "logs"]. Each one costs about $0.01 per hour per availability zone. | `set(string)` | `[]` | no |
| kms\_deletion\_window\_in\_days | Waiting period, in days, before the flow log KMS key is deleted after a destroy. | `number` | `30` | no |
| nat\_gateway\_mode | Outbound IPv4 internet access for private subnets: none, single (one gateway shared by every zone) or per\_az (one gateway in each zone). See ADR-0004. | `string` | `"none"` | no |
| tags | Tags added to every resource, on top of the provider default tags. | `map(string)` | `{}` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| endpoints\_security\_group\_id | ID of the security group attached to the interface endpoints. Null when interface\_endpoints is empty. |
| flow\_logs\_bucket\_name | Name of the bucket that receives the flow logs. Null when flow\_logs\_enabled is false. |
| nat\_gateway\_public\_ips | Public IPv4 addresses of the NAT gateways. Empty when nat\_gateway\_mode is none. |
| private\_route\_table\_ids | IDs of the private route tables, one per zone, in the order of availability\_zones. |
| private\_subnet\_ids | IDs of the private subnets, in the order of availability\_zones. |
| public\_route\_table\_id | ID of the route table shared by the public subnets. |
| public\_subnet\_ids | IDs of the public subnets, in the order of availability\_zones. |
| vpc\_cidr\_block | IPv4 CIDR block of the VPC. |
| vpc\_id | ID of the VPC. |
| vpc\_ipv6\_cidr\_block | IPv6 CIDR block of the VPC. Null when enable\_ipv6 is false. |
<!-- END_TF_DOCS -->
