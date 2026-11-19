# Contributing

Bug reports, fixes and new stacks are welcome.

## Development setup

Every tool is pinned in `.tool-versions`. With [asdf](https://asdf-vm.com):

```bash
for tool in $(cut -d' ' -f1 .tool-versions); do asdf plugin add "$tool"; done
asdf install
pre-commit install
```

`make check` runs the same checks as CI: formatting, validation, TFLint, Trivy, documentation drift and module tests. None of them need AWS credentials.

## Workflow

1. Open an issue before starting anything larger than a fix, so the approach can be agreed on first.
2. Branch from `main`, for example `feat/network-flow-logs`.
3. Keep each pull request to one module or stack.
4. Title the pull request with a [Conventional Commit](https://www.conventionalcommits.org) scoped to the module or stack, for example `feat(network): add interface endpoints`.
5. Pull requests are squash-merged once CI passes.

## Definition of done for a module

- It follows the layout and rules in [docs/conventions.md](docs/conventions.md).
- Every variable has a type and a description, with validation where an invalid value would otherwise fail only at apply time.
- Defaults are secure and inexpensive. Production settings are explicit inputs.
- `examples/basic` and `examples/complete` exist and validate.
- `tests/` covers its logic and validations.
- The README states its purpose, an architecture diagram, an estimated cost and its security considerations. Inputs and outputs are regenerated with `make docs`.
- It has been deployed and destroyed from an `environments/` configuration, and the plan summary is in the pull request.
- Non-obvious decisions are recorded in an ADR and `CHANGELOG.md` is updated.

## Deploying

Plans and applies run from a workstation, never from CI. See [ADR-0002](docs/adr/0002-plan-and-apply-from-a-workstation.md).
