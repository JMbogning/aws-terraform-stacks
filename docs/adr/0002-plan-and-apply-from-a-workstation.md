# 0002. Plan and apply from a workstation

- Status: Accepted
- Date: 2026-11-20

## Context

Changes are applied by a single maintainer. Creating an identity for a CI system in the target AWS account requires additional approval, and a pipeline that can change infrastructure becomes a high-value target in its own right.

## Decision

- CI runs checks that need no cloud credentials: formatting, validation, linting, security scanning, documentation drift and `terraform test` with mocked providers.
- Plans and applies run from the maintainer's workstation through `make`:
  - `make plan` saves the plan and records the commit it was created from;
  - `make apply` runs only on a clean `main` that matches `origin/main`, and only applies a plan created from that commit.
- Each environment restricts the AWS provider to its account with `allowed_account_ids`. Account IDs live in an uncommitted `local.auto.tfvars`.
- Pull requests that change an environment include the plan summary.

## Consequences

- GitHub Actions holds no AWS credentials and no OIDC trust relationship is needed.
- Applies depend on the operator's workstation and credentials. Short-lived credentials from IAM Identity Center are preferred over long-lived access keys.
- Drift is detected by running `make plan`, not by a scheduled pipeline.
- This decision should be revisited if more than one person applies changes, since a shared pipeline then becomes the simpler way to serialise and audit applies.
