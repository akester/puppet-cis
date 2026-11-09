# 4 Host Based Firewall

Controls from chapter 4 of the CIS Debian Linux 13 Benchmark v1.1.0. The
section-level status is in [cis-coverage.md](../cis-coverage.md).

## Controls

The benchmark's chapter 4 configures ufw. The fleet uses firewalld instead,
set up by the control repo (`harden::firewall`, with per-role zones and
`harden::firewall_rule`), because the rules are site-specific. Each ufw rule
has a firewalld equivalent there.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| — | 4.1.1 | ufw installed | — | Replaced | — | Control repo: firewalld is the firewall. |
| — | 4.1.2 | ufw service configured | — | Replaced | — | Control repo: firewalld enabled and running. |
| — | 4.1.3 | Incoming default policy | — | Replaced | — | Control repo: the `public` zone's target is `DROP`, and rules, services and ports not managed by Puppet are purged. |
| — | 4.1.4 | Outgoing default policy | — | Replaced | — | Control repo. |
| — | 4.1.5 | Routed default policy | — | Replaced | — | Control repo. |

## Deviations

### 4.1: firewalld instead of ufw

firewalld is managed by `puppet/firewalld` from the control repo. Zones and
open ports depend on each host's role, so they don't belong in the baseline.
Wazuh SCA's ufw checks are expected to fail on every host.
