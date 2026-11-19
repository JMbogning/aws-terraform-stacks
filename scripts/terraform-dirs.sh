#!/usr/bin/env bash
# Prints every directory that contains Terraform files, one per line.
set -euo pipefail

find "${1:-.}" -type f -name '*.tf' -not -path '*/.terraform/*' -exec dirname {} \; | sort -u
