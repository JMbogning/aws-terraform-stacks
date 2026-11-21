# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Pinned toolchain with pre-commit hooks, TFLint, Trivy and terraform-docs.
- CI workflow for formatting, validation, linting, security scanning, documentation drift and tests.
- OpenSSF Scorecard workflow and Renovate configuration.
- Contribution guidelines, security policy, conventions and architecture decision records.
- `state-backend`: S3 bucket for Terraform state with versioning, KMS encryption, TLS-only access and native locking, with tests and a runbook.
- ADR-0003: environments read the state bucket from an uncommitted `backend.hcl`.
- `make test`, `make docs` and `make docs-check` cover bootstrap configurations.
