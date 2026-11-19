# AWS Terraform Stacks

[![CI](https://github.com/JMbogning/aws-terraform-stacks/actions/workflows/ci.yml/badge.svg)](https://github.com/JMbogning/aws-terraform-stacks/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/JMbogning/aws-terraform-stacks/badge)](https://scorecard.dev/viewer/?uri=github.com/JMbogning/aws-terraform-stacks)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.17-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

Opinionated AWS infrastructure with Terraform. Every decision explained, every cost estimated, every operation documented.

Each stack is built the way it would be in a company: reusable modules, separate environments and automated checks. Each one also ships the documentation needed to run it after the first deployment: architecture decision records, cost estimates and runbooks.

## Stacks

| Stack | What it deploys | Estimated cost (dev) | Status |
|---|---|---|---|
| state-backend | S3 bucket for Terraform state with versioning, encryption and native locking | < $0.01/h | Planned |
| network | Multi-AZ VPC, optional NAT gateways, VPC endpoints and flow logs | $0.00 to $0.05/h | Planned |
| rds-postgres | Private PostgreSQL with credentials managed by Secrets Manager and automated backups | ~$0.02/h | Planned |
| static-site | Private S3 origin behind CloudFront, HTTPS only, security headers | < $0.01/h | Planned |
| observability | Dashboards, alarms and notifications for the other stacks | < $0.01/h | Planned |
| three-tier-app | WAF, Application Load Balancer, ECS Fargate service and PostgreSQL | ~$0.10/h | Planned |
| eks-cluster | EKS with access entries, Pod Identity and managed add-ons | ~$0.24/h | Planned |

Estimates use on-demand prices in `us-east-1`, the default settings of each stack and no traffic. Every stack can be destroyed with a single command.

## Principles

- **Modules hold logic, environments hold values.** The same module is deployed to `dev` and `prod` with different inputs.
- **One state per stack and environment.** A failed change cannot affect the state of an unrelated stack.
- **Secure and inexpensive defaults.** Encryption is on and nothing is public unless that is the purpose of the stack. Production settings such as Multi-AZ or deletion protection are explicit inputs.
- **No cloud credentials in CI.** Pipelines run formatting, validation, linting, security scanning and tests. Plans and applies run from an operator workstation ([ADR-0002](docs/adr/0002-plan-and-apply-from-a-workstation.md)).
- **Decisions are written down** as [architecture decision records](docs/adr).

## Repository layout

```text
.
├── bootstrap/state-backend/     # creates the state bucket and keeps a local state
├── modules/<name>/              # reusable modules with examples and tests
├── environments/<env>/<stack>/  # deployable configurations, one state each
├── docs/
│   ├── adr/                     # architecture decision records
│   ├── runbooks/                # operating procedures
│   └── conventions.md           # naming, tagging and versioning rules
└── scripts/                     # helpers used by the Makefile
```

## Getting started

Requirements: [asdf](https://asdf-vm.com) or another tool that reads `.tool-versions`, the [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), and credentials for an AWS account you are allowed to change.

```bash
git clone https://github.com/JMbogning/aws-terraform-stacks.git
cd aws-terraform-stacks
for tool in $(cut -d' ' -f1 .tool-versions); do asdf plugin add "$tool"; done
asdf install
pre-commit install
make check
```

## Deploying a stack

```bash
export AWS_PROFILE=<profile>
make plan STACK=dev/network      # saves the plan
make apply STACK=dev/network     # applies it, from an up-to-date main branch only
make destroy STACK=dev/network
```

`make help` lists every available target.

## Documentation

- [Conventions](docs/conventions.md)
- [Architecture decision records](docs/adr)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)

## License

Apache License 2.0. See [LICENSE](LICENSE).
