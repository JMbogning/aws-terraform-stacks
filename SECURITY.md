# Security policy

## Reporting a vulnerability

Please do not report security issues in public issues or pull requests. Use [private vulnerability reporting](https://github.com/JMbogning/aws-terraform-stacks/security/advisories/new) instead.

Include the affected module or stack, the configuration needed to reproduce the issue and its impact. You will receive an acknowledgement within five working days.

## Scope

In scope: configurations in this repository that weaken security when used as documented, such as unintended public exposure, missing encryption or overly broad IAM permissions.

Out of scope: vulnerabilities in Terraform, its providers or AWS services. Please report them to their maintainers.

## Supported versions

Fixes are made on `main` and published in the next release. Older releases are not patched.
