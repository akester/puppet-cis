# 3 Network

Controls from chapter 3 of the CIS Debian Linux 13 Benchmark v1.1.0. The
section-level status is in [cis-coverage.md](../cis-coverage.md).

## Controls

### Network devices (3.1)

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| — | 3.1.1 | IPv6 status identified | enabled | N/A | `baseline::sysctl::manage_ipv6` | Manual rule. IPv6 stays enabled in the kernel everywhere; only some hosts are configured to use it. The 3.3.2 IPv6 sysctls are written either way. |
| hl-kmod-015 | 3.1.2 | Wireless interfaces | `cfg80211` not loadable | Enforced | `baseline::kmod::allow` (`cfg80211`) | Denies cfg80211, which every Wi-Fi driver depends on, rather than listing each driver. See below. |
| hl-service-022 | 3.1.3 | `bluez` package | purged | Enforced | `baseline::services::allow` (`bluetooth`) | In `baseline::services`. Also removes `pi-bluetooth` where it's installed. |
| hl-kmod-016 | 3.1.3 | `bluetooth` module | not loadable | Enforced | `baseline::kmod::allow` (`bluetooth`) | Not required by CIS, which checks the package. The kernel side, same approach as cfg80211: every Bluetooth driver depends on it. |

### Network kernel parameters (3.3)

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
| hl-sysctl-023 | 3.3.1.16 | `net.ipv4.conf.all.log_martians` | `1` | Enforced | `baseline::sysctl::log_martians` | `0` when `ipv4_forwarding` is on; see below. |
| hl-sysctl-024 | 3.3.1.17 | `net.ipv4.conf.default.log_martians` | `1` | Enforced | `baseline::sysctl::log_martians` |  |
| hl-sysctl-025 | 3.3.1.18 | `net.ipv4.tcp_syncookies` | `1` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-026 | 3.3.1.19 | `net.ipv4.conf.all.route_localnet` | `0` | Enforced | `baseline::manage_sysctl` | New relative to os_hardening. |
| hl-sysctl-036 | — | `net.ipv4.tcp_rfc1337` | `1` | Enforced | `baseline::manage_sysctl` | Not CIS. Carried over from os_hardening; see below. |
| hl-sysctl-027 | 3.3.2.1 | `net.ipv6.conf.all.forwarding` | `0` | Enforced | `baseline::sysctl::ipv6_forwarding` |  |
| hl-sysctl-028 | 3.3.2.2 | `net.ipv6.conf.default.forwarding` | `0` | Enforced | `baseline::sysctl::ipv6_forwarding` |  |
| hl-sysctl-029 | 3.3.2.3 | `net.ipv6.conf.all.accept_redirects` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-030 | 3.3.2.4 | `net.ipv6.conf.default.accept_redirects` | `0` | Enforced | `baseline::manage_sysctl` | New relative to os_hardening. |
| hl-sysctl-031 | 3.3.2.5 | `net.ipv6.conf.all.accept_source_route` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-032 | 3.3.2.6 | `net.ipv6.conf.default.accept_source_route` | `0` | Enforced | `baseline::manage_sysctl` |  |
| hl-sysctl-033 | 3.3.2.7 | `net.ipv6.conf.all.accept_ra` | `0` | Enforced | `baseline::manage_sysctl` | Already set by os_hardening. Safe fleet-wide: routers send no RAs and IPv6 servers are statically addressed, so no parameter. |
| hl-sysctl-034 | 3.3.2.8 | `net.ipv6.conf.default.accept_ra` | `0` | Enforced | `baseline::manage_sysctl` |  |

### Network kernel modules (3.2)

All Level 1 Server. Same mechanism as the 1.1.1 modules; see
[1-initial-setup.md](1-initial-setup.md#kernel-modules-111).

| ID | CIS | Module | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-kmod-008 | 3.2.1 | `atm` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-009 | 3.2.2 | `can` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-010 | 3.2.3 | `dccp` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-011 | 3.2.4 | `rds` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-012 | 3.2.5 | `sctp` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-013 | 3.2.6 | `tipc` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| — | 3.2.7 | Unneeded network protocol modules | — | Undecided | — | Manual review in CIS; no fixed list. |

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
This is the same behavior as under os_hardening. Tested on a K3s node with the
default (`1`): no problems. Forcing strict mode per interface is parked for
now. Hosts with asymmetric routing set `baseline::sysctl::rp_filter: 2`.

### log_martians follows forwarding (hl-sysctl-023, 024)

`log_martians` only logs; the kernel and rp_filter do the dropping. On
forwarding hosts (Docker, K3s, runners), container and pod traffic regularly
looks martian, so the kernel log and Wazuh would fill up with noise. On plain
servers a martian is rare, so a log line there is worth looking at.

So `baseline::sysctl::log_martians` defaults to the opposite of
`ipv4_forwarding`: on (CIS) for normal hosts, off for forwarding hosts. Those
hosts deviate from 3.3.1.16 and 3.3.1.17, which CIS already treats as out of
scope for routers. Setting `log_martians` explicitly in Hiera overrides the
default either way.

This replaces the old fleet-wide `os_hardening::enable_log_martians: false`.

### hl-sysctl-036: tcp_rfc1337 (not CIS)

Keeps TIME_WAIT sockets alive when a reset arrives, instead of closing them
early (TIME-WAIT assassination, RFC 1337). The security gain is small and the
cost is negligible. It's kept because the fleet already runs it under
os_hardening, so dropping it would be a behavior change for no benefit.

### hl-kmod-015: wireless through cfg80211

CIS's remediation writes an `install`/`blacklist` pair for every module under
the running kernel's `drivers/net/wireless`, which changes with each kernel
and differs on the Raspberry Pi kernel. Every Wi-Fi driver depends on
cfg80211 instead, and modprobe runs a dependency's `install` command before
loading the driver, so denying cfg80211 alone stops them all (checked with
`modprobe --show-depends brcmfmac`).

Like the other modules, it takes effect at the next boot: a Wi-Fi interface
that's already up stays up until then, and the CIS audit, which looks at the
driver of any wireless interface present, passes once it's gone.

### Not carried over from os_hardening

os_hardening also set these on every host. They aren't in CIS and the
baseline leaves them at the kernel default. They stay in effect until the old
`/etc/sysctl.conf` entries are removed (see [migration.md](../migration.md)).

| Setting | os_hardening | Kernel default | Why dropped |
|---|---|---|---|
| `net.ipv4.tcp_timestamps` | `0` | `1` | Disabling hurts TCP performance and PAWS protection; the uptime leak it guarded against is long fixed. |
| `net.ipv4.conf.{all,default}.arp_ignore` | `1` | `0` | Can break VIPs and load balancers (K3s, keepalived). Opt-in if ever needed. |
| `net.ipv4.conf.{all,default}.arp_announce` | `2` | `0` | Same as `arp_ignore`. |
| `net.ipv4.conf.{all,default}.shared_media` | `1` | `1` | Already the default. |
| `net.ipv4.icmp_ratelimit` | `100` | `1000` | Tuning, not hardening. |
| `net.ipv4.icmp_ratemask` | `88089` | `6168` | Tuning, not hardening. |
| `net.ipv6.conf.all.disable_ipv6` | `0` | `0` | IPv6 status is CIS 3.1.1, handled separately. |

