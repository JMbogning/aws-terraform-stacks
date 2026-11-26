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
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| availability\_zones | Availability zones that receive one public and one private subnet each, for example ["us-east-1a", "us-east-1b"]. | `list(string)` | n/a | yes |
| name | Prefix of every resource name, for example ats-dev. | `string` | n/a | yes |
| cidr\_block | IPv4 CIDR block of the VPC, between /16 and /20. Each subnet takes a sixteenth of it. | `string` | `"10.0.0.0/16"` | no |
| nat\_gateway\_mode | Outbound IPv4 internet access for private subnets: none, single (one gateway shared by every zone) or per\_az (one gateway in each zone). See ADR-0004. | `string` | `"none"` | no |
| tags | Tags added to every resource, on top of the provider default tags. | `map(string)` | `{}` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| nat\_gateway\_public\_ips | Public IPv4 addresses of the NAT gateways. Empty when nat\_gateway\_mode is none. |
| private\_route\_table\_ids | IDs of the private route tables, one per zone, in the order of availability\_zones. |
| private\_subnet\_ids | IDs of the private subnets, in the order of availability\_zones. |
| public\_route\_table\_id | ID of the route table shared by the public subnets. |
| public\_subnet\_ids | IDs of the public subnets, in the order of availability\_zones. |
| vpc\_cidr\_block | IPv4 CIDR block of the VPC. |
| vpc\_id | ID of the VPC. |
<!-- END_TF_DOCS -->
