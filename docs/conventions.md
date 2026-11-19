# Conventions

## Layout

| Path | Contains |
|---|---|
| `modules/<name>/` | A reusable module. No provider or backend configuration and no environment-specific values. |
| `modules/<name>/examples/basic/`, `.../complete/` | Runnable examples, validated in CI. |
| `modules/<name>/tests/` | `terraform test` files using mocked providers. |
| `environments/<env>/<stack>/` | A root configuration that calls modules with the values of one environment. |
| `bootstrap/<name>/` | Configurations that must exist before any remote state. |

A module contains `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` and `README.md`. Large modules split `main.tf` by concern, for example `iam.tf` and `security.tf`.

## Naming

- Terraform identifiers use `snake_case`. When a module creates a single resource of a type, that resource is named `this`.
- Modules take a `name` input and derive every AWS resource name from it, for example `${var.name}-vpc`.
- Environments set `name` to `<project>-<environment>`, for example `ats-dev`.

## Tags

Environments apply these tags through the provider's `default_tags`:

| Tag | Example | Purpose |
|---|---|---|
| `Project` | `aws-terraform-stacks` | Groups resources and costs |
| `Environment` | `dev` | Separates environments in billing and IAM conditions |
| `Stack` | `network` | Identifies the configuration that manages the resource |
| `Owner` | `platform` | Who to contact |
| `CostCenter` | `engineering` | Cost allocation |
| `ManagedBy` | `terraform` | Signals that manual changes will be reverted |
| `Repository` | `github.com/JMbogning/aws-terraform-stacks` | Where the code lives |

Modules also accept a `tags` input, applied where provider default tags are not propagated, such as launch template tag specifications.

## Variables and outputs

- Every variable has a `type` and a `description`.
- A `validation` block is added when an invalid value would otherwise fail only at apply time.
- Defaults are secure and inexpensive. Production settings such as Multi-AZ, deletion protection or longer retention are explicit inputs.
- Sensitive values are marked `sensitive = true` and never have a default.
- Every output has a `description`.

## Versions

- Modules declare lower bounds only: `required_version = ">= 1.17"` and `version = ">= 6.0"` for providers.
- Environments pin providers with `~>` and commit `.terraform.lock.hcl`.
- Releases are tagged `vMAJOR.MINOR.PATCH`. Removing or renaming a module input or output is a breaking change.

## State and cross-stack references

- Each environment configuration has its own state key: `<env>/<stack>/terraform.tfstate`.
- Values shared between stacks are published as SSM parameters under `/<project>/<env>/<stack>/<key>` and read with data sources. `terraform_remote_state` is not used, because it requires read access to the entire state of another stack.

## Account guard

Every environment sets `allowed_account_ids` on the AWS provider. The value comes from an uncommitted `local.auto.tfvars`, so account IDs are never published.

## Commits

[Conventional Commits](https://www.conventionalcommits.org), scoped to the module or stack: `feat(network): add flow logs`, `fix(eks-cluster): pin add-on versions`, `docs(adr): record state backend decision`.
