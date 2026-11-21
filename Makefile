SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

STACK ?=
TF_DIRS = $(shell scripts/terraform-dirs.sh)
MODULE_DIRS = $(shell find modules -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
BOOTSTRAP_DIRS = $(shell find bootstrap -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

.PHONY: help
help: ## List available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Checks: no AWS credentials needed. CI runs `make check`.

.PHONY: fmt
fmt: ## Format Terraform files
	terraform fmt -recursive

.PHONY: fmt-check
fmt-check: ## Fail if Terraform files are not formatted
	terraform fmt -recursive -check -diff

.PHONY: validate
validate: ## Validate every Terraform directory
	@for dir in $(TF_DIRS); do \
		echo "==> $$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false -no-color > /dev/null; \
		terraform -chdir="$$dir" validate -no-color; \
	done

.PHONY: lint
lint: ## Run TFLint on every directory
	tflint --init --config "$(CURDIR)/.tflint.hcl"
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

.PHONY: scan
scan: ## Fail on HIGH and CRITICAL misconfigurations
	trivy config --exit-code 1 --severity HIGH,CRITICAL --skip-dirs "**/.terraform" .

.PHONY: docs
docs: ## Generate module and bootstrap documentation
	@for dir in $(MODULE_DIRS) $(BOOTSTRAP_DIRS); do \
		terraform-docs --config "$(CURDIR)/.terraform-docs.yml" "$$dir"; \
	done

.PHONY: docs-check
docs-check: ## Fail if module or bootstrap documentation is out of date
	@for dir in $(MODULE_DIRS) $(BOOTSTRAP_DIRS); do \
		terraform-docs --config "$(CURDIR)/.terraform-docs.yml" --output-check "$$dir"; \
	done

.PHONY: test
test: ## Run module and bootstrap tests
	@for dir in $(MODULE_DIRS) $(BOOTSTRAP_DIRS); do \
		[[ -d "$$dir/tests" ]] || continue; \
		echo "==> $$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false -no-color > /dev/null; \
		terraform -chdir="$$dir" test -no-color; \
	done

.PHONY: check
check: fmt-check validate lint scan docs-check test ## Run every check that CI runs

# Deployment: requires AWS credentials. See docs/adr/0002-plan-and-apply-from-a-workstation.md.

.PHONY: plan
plan: ## Plan a stack and save the plan, e.g. make plan STACK=dev/network
	@scripts/stack.sh plan "$(STACK)"

.PHONY: apply
apply: ## Apply the saved plan of a stack (clean, up-to-date main only)
	@scripts/stack.sh apply "$(STACK)"

.PHONY: destroy
destroy: ## Destroy a stack (clean, up-to-date main only)
	@scripts/stack.sh destroy "$(STACK)"
