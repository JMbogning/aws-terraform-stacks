# 0001. Repository layout

- Status: Accepted
- Date: 2026-11-20

## Context

The repository hosts several independent stacks (networking, databases, Kubernetes, applications), each deployed to more than one environment. Reusable code has to stay separate from environment-specific values, and a failed change to one stack must not put the state of another at risk.

## Decision

- `modules/<name>` contains reusable modules. They have no provider or backend configuration and no environment-specific values. Each module ships with examples and tests.
- `environments/<env>/<stack>` contains root configurations that call modules with the values of one environment. Each one has its own state.
- `bootstrap/state-backend` creates the bucket that stores every other state. It keeps a local state, because it cannot store its state in a bucket that does not exist yet.
- Environments are separated by directory, not by Terraform workspaces.

## Consequences

- Promoting a change from `dev` to `prod` is a separate, reviewable change under `environments/prod`.
- Backend and provider blocks are repeated in each environment directory. This duplication is accepted in exchange for configurations that can be read on their own.
- Workspaces were rejected: they share one backend configuration and one set of credentials, which makes applying to the wrong environment too easy.
