# 0004. NAT gateway strategy

- Status: Accepted
- Date: 2026-11-26

## Context

Private subnets need a way to reach the IPv4 internet, for package updates or external APIs. A NAT gateway costs about $0.045 per hour plus $0.005 per hour for its public IPv4 address, and $0.045 per gigabyte processed, even when nothing uses it. A gateway lives in one availability zone: if that zone fails, every subnet that depends on it loses outbound access, and traffic from other zones pays cross-zone transfer.

Development environments are idle most of the time, while production needs to survive the loss of a zone.

## Decision

The network module takes a `nat_gateway_mode` input:

| Mode | Gateways | Fixed cost | Use |
|---|---|---|---|
| `none` (default) | 0 | $0 | Workloads that only call AWS services |
| `single` | 1, in the first zone | about $0.05/h | Development environments that need the internet |
| `per_az` | 1 per zone | about $0.05/h per zone | Production |

Without NAT, private subnets still reach S3 and DynamoDB through free gateway endpoints, other AWS services through interface endpoints, and IPv6 destinations through a free egress-only gateway.

## Consequences

- An idle development network costs nothing. Internet access is an explicit, visible choice in the environment configuration.
- With `single`, an outage of the first zone cuts outbound access for every zone. This is accepted outside production.
- Changing the mode replaces the private default routes, which interrupts outbound connections for a few seconds.
- Rejected: NAT instances, which are cheaper but must be patched and made highly available by hand; one gateway per zone everywhere, which costs about $70 per month for an idle two-zone development network.
