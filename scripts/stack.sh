#!/usr/bin/env bash
# Plans, applies or destroys a stack from an operator workstation.
#
#   scripts/stack.sh plan    <env>/<stack>
#   scripts/stack.sh apply   <env>/<stack>
#   scripts/stack.sh destroy <env>/<stack>
#
# `plan` saves the plan and records the commit it was created from.
# `apply` only runs on a clean main that matches origin/main, and only applies
# a plan created from that exact commit. See docs/adr/0002.
set -euo pipefail

usage() {
  echo "usage: $0 <plan|apply|destroy> <env>/<stack>" >&2
  exit 1
}

die() {
  echo "error: $*" >&2
  exit 1
}

[[ $# -eq 2 && -n "$2" ]] || usage

action="$1"
stack="$2"
dir="environments/${stack}"
plan_file="tfplan"
commit_file="tfplan.commit"

[[ -d "$dir" ]] || die "$dir does not exist"

require_clean_main() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  [[ "$branch" == "main" ]] || die "$action is only allowed from main (current branch: $branch)"
  [[ -z "$(git status --porcelain)" ]] || die "the working tree has uncommitted changes"
  git fetch --quiet origin main
  [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || die "local main does not match origin/main"
}

current_revision() {
  if [[ -z "$(git status --porcelain)" ]]; then
    git rev-parse HEAD
  else
    echo "dirty"
  fi
}

case "$action" in
  plan)
    terraform -chdir="$dir" init -input=false
    terraform -chdir="$dir" plan -input=false -out="$plan_file"
    current_revision > "$dir/$commit_file"
    ;;
  apply)
    require_clean_main
    [[ -f "$dir/$plan_file" ]] || die "no saved plan, run: make plan STACK=$stack"
    [[ "$(cat "$dir/$commit_file" 2> /dev/null)" == "$(git rev-parse HEAD)" ]] \
      || die "the saved plan was not created from the current commit, run: make plan STACK=$stack"
    terraform -chdir="$dir" apply -input=false "$plan_file"
    rm -f "$dir/$plan_file" "$dir/$commit_file"
    ;;
  destroy)
    require_clean_main
    terraform -chdir="$dir" init -input=false
    terraform -chdir="$dir" destroy
    ;;
  *)
    usage
    ;;
esac
