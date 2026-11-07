# 3 Network

Controls from chapter 3 of the CIS Debian Linux 13 Benchmark v1.1.0. The
section-level status is in [cis-coverage.md](../cis-coverage.md).

## Controls

All 3.3 recommendations are Level 1 Server. They are written to
`/etc/sysctl.d/60-baseline.conf` by `baseline::sysctl`, like the 1.5 sysctls.
The IPv6 rows (027–034) are skipped when `baseline::sysctl::manage_ipv6` is
false; CIS treats them as not applicable when IPv6 is disabled.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-sysctl-008 | 3.3.1.1 | `net.ipv4.ip_forward` | `0` | Enforced | `baseline::sysctl::ipv4_forwarding` | See forwarding below. |
| hl-sysctl-009 | 3.3.1.2 | `net.ipv4.conf.all.forwarding` | `0` | Enforced | `baseline::sysctl::ipv4_forwarding` | Same switch as 008; the kernel ties them together. |
| hl-sysctl-010 | 3.3.1.3 | `net.ipv4.conf.default.forwarding` | `0` | Enforced | `baseline::sysctl::ipv4_forwarding` |  |
| hl-sysctl-011 | 3.3.1.4 | `net.ipv4.conf.all.send_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-012 | 3.3.1.5 | `net.ipv4.conf.default.send_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-013 | 3.3.1.6 | `net.ipv4.icmp_ignore_bogus_error_responses` | `1` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-014 | 3.3.1.7 | `net.ipv4.icmp_echo_ignore_broadcasts` | `1` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-015 | 3.3.1.8 | `net.ipv4.conf.all.accept_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-016 | 3.3.1.9 | `net.ipv4.conf.default.accept_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-017 | 3.3.1.10 | `net.ipv4.conf.all.secure_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-018 | 3.3.1.11 | `net.ipv4.conf.default.secure_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-019 | 3.3.1.12 | `net.ipv4.conf.all.rp_filter` | `1` | Enforced | `baseline::sysctl::rp_filter` (1–2) | Debian ships `2`. See rp_filter below. |
| hl-sysctl-020 | 3.3.1.13 | `net.ipv4.conf.default.rp_filter` | `1` | Enforced | `baseline::sysctl::rp_filter` (1–2) |  |
| hl-sysctl-021 | 3.3.1.14 | `net.ipv4.conf.all.accept_source_route` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-022 | 3.3.1.15 | `net.ipv4.conf.default.accept_source_route` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-023 | 3.3.1.16 | `net.ipv4.conf.all.log_martians` | `1` | Enforced | `baseline::sysctl::log_martians` | Fleet sets `false`; see below. |
| hl-sysctl-024 | 3.3.1.17 | `net.ipv4.conf.default.log_martians` | `1` | Enforced | `baseline::sysctl::log_martians` |  |
| hl-sysctl-025 | 3.3.1.18 | `net.ipv4.tcp_syncookies` | `1` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-026 | 3.3.1.19 | `net.ipv4.conf.all.route_localnet` | `0` | Enforced | `baseline::manage_sysctl` | New relative to os_hardening. |
| hl-sysctl-027 | 3.3.2.1 | `net.ipv6.conf.all.forwarding` | `0` | Enforced | `baseline::sysctl::ipv6_forwarding` |  |
| hl-sysctl-028 | 3.3.2.2 | `net.ipv6.conf.default.forwarding` | `0` | Enforced | `baseline::sysctl::ipv6_forwarding` |  |
| hl-sysctl-029 | 3.3.2.3 | `net.ipv6.conf.all.accept_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-030 | 3.3.2.4 | `net.ipv6.conf.default.accept_redirects` | `0` | Enforced | `baseline::manage_sysctl` | New relative to os_hardening. |
| hl-sysctl-031 | 3.3.2.5 | `net.ipv6.conf.all.accept_source_route` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-032 | 3.3.2.6 | `net.ipv6.conf.default.accept_source_route` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-033 | 3.3.2.7 | `net.ipv6.conf.all.accept_ra` | `0` | Enforced | `baseline::manage_sysctl` | Already set by os_hardening; hosts need static IPv6 or DHCPv6. |
| hl-sysctl-034 | 3.3.2.8 | `net.ipv6.conf.default.accept_ra` | `0` | Enforced | `baseline::manage_sysctl` |  |

## Deviations

### Forwarding on container hosts and K3s nodes (hl-sysctl-008..010, 027, 028)

CIS treats a router as out of scope for 3.3.1 and for the IPv6 forwarding
rules. Docker hosts, K3s nodes and the GitLab runners forward packets for
their containers and pods, so they count as routers here. They set
`baseline::sysctl::ipv4_forwarding: true` in Hiera (os_hardening's
`enable_ipv4_forwarding`). If forwarding stays off, Docker turns it back on
at startup and Puppet flips it off again on every run, which breaks
container networking.

IPv6 forwarding (`ipv6_forwarding`) is off everywhere today. A host that
routes IPv6 for containers or for the Route64 tunnel needs it turned on.

The redirect, source-route and other rules stay enforced on these hosts.

### rp_filter (hl-sysctl-019, 020)

The kernel uses the higher of `conf.all.rp_filter` and the per-interface
value. On trixie, `linux-sysctl-defaults` ships
`/usr/lib/sysctl.d/50-default.conf` with `net.ipv4.conf.*.rp_filter = 2`, and
systemd re-applies it to each new interface. So interfaces stay in loose mode
even with `all` set to 1. The CIS check only looks at `all` and `default`, so it passes either way.
This is the same behavior as under os_hardening; whether to force strict mode
per interface is still open. Hosts with asymmetric routing set
`baseline::sysctl::rp_filter: 2`.

### log_martians (hl-sysctl-023, 024)

The baseline defaults to CIS (`1`). The fleet's `common.yaml` turns it off
(`enable_log_martians: false`), probably because of kernel log noise on
container and multi-homed hosts. Until that's revisited, set
`baseline::sysctl::log_martians: false` in `common.yaml` at the switch, and
record it as a fleet-wide deviation.
