# CIS coverage and deviations

Reference: **CIS Debian Linux 13 Benchmark v1.1.0**. Sections are listed by
number and title only; see the benchmark itself for the recommendation text.

Target profile: **Level 1 Server**. Level 2 recommendations are out of scope unless listed as an explicit addition.

This page is the section-level overview. Individual controls, with their IDs,
parameters, and deviations, are in [controls/](controls/README.md), one file
per CIS chapter. Host migration steps are in [migration.md](migration.md).

## Status key

| Status | Meaning |
|---|---|
| Enforced | Puppet manages it (`baseline::*`). |
| Monitored | Wazuh SCA check only; Puppet does not change it. |
| Replaced | The intent is met by a different control (named in the notes). |
| N/A | Doesn't apply to this fleet. |
| Omitted | Deliberately not implemented. Needs a rationale below. |
| Partial | Some recommendations in the section are implemented, others deviate. |
| Planned / Undecided | Not implemented yet / no decision yet. |

Statuses marked *(proposed)* come from the migration brief and haven't been
confirmed yet.

## Section overview

| CIS | Section | Status | Notes |
|---|---|---|---|
| 1.1.1 | Filesystem kernel modules | Enforced, with exceptions | Level 1 rules enforced, including the 1.1.1.11 catch-all; per-host `allow`. `overlay` (Level 2) stays loadable for containers. |
| 1.1.2 | Filesystem partitions | Partial | 1.1.2.1 (`/tmp`) enforced except `noexec`; 1.1.2.2 (`/dev/shm`) and 1.1.2.5 (`/var/tmp`, a tmpfs) enforced. 1.1.2.3, 1.1.2.4, 1.1.2.6, 1.1.2.7 (`/home`, `/var`, `/var/log`, `/var/log/audit`) N/A: on `/`, not separate partitions. |
| 1.2.1 | Package repositories | Enforced, with monitored rules | Sources are managed in the control repo (apt.kester.cloud mirror), all with Signed-By (1.2.1.1). 1.2.1.2 omitted (Level 2). Key directory permissions enforced (1.2.1.4, 1.2.1.7); the directories puppetlabs/apt owns (1.2.1.5, 1.2.1.8), file permissions and https monitored (1.2.1.3, 1.2.1.6, 1.2.1.9–1.2.1.11). Repository security settings enforced (1.2.1.12–1.2.1.15). |
| 1.2.2 | Package updates | Replaced | unattended-upgrades, configured in the control repo (`base::unattended`) because its allow list covers site repositories. |
| 1.3.1 | AppArmor | Enforced, with monitored rules | Packages (1.3.1.1) and the 1.3.1.4 sysctl enforced. 1.3.1.2 monitored: enabled by default on Debian 13. 1.3.1.3 omitted (Level 2). |
| 1.4.1 | Bootloader password | Omitted | Physical hosts are on site only; on VMs a Proxmox control-plane compromise gets past it anyway. |
| 1.4.2 | Bootloader config access | Enforced | `grub.cfg` root:root `0600` where it exists. |
| 1.5 | Additional process hardening | Enforced | sysctls (1.5.1–1.5.5, 1.5.8, 1.5.9) enforced; prelink and apport purged (1.5.6, 1.5.7); core dumps off via limits.d and systemd-coredump (1.5.10–1.5.12). |
| 1.6 | Command line warning banners | Enforced, with monitored rules | `/etc/motd`, `/etc/issue`, `/etc/issue.net` content and access, and the pam_motd content, enforced (1.6.1–1.6.4, 1.6.6–1.6.9), and update-notifier masked on Ubuntu (1.6.11, 1.6.12). sshd banner and its file (1.6.5, 1.6.10) monitored; set by the control repo's SSH config. |
| 1.7 | GNOME Display Manager | N/A | No GDM installs in the fleet. |
| 2.1 | Server services | Partial *(proposed)* | Some hosts intentionally run DHCP, NFS, Samba, web, and NTP services; per-role exceptions. |
| 2.2 | Client services | Planned → Enforced | |
| 2.3 | Time synchronization | Planned | Must not conflict with the public NTP server's config. |
| 2.4 | Job schedulers (cron, at) | Planned → Enforced | Parity with os_hardening. |
| 3.1.1 | IPv6 status | Enforced *(proposed)* | IPv6 stays on (Route64 tunnel, NPTv6, ULA). |
| 3.1.2–3.1.3 | Wireless, Bluetooth | Undecided | |
| 3.2 | Network kernel modules | Enforced | 3.2.1–3.2.6; 3.2.7 (manual review) undecided. |
| 3.3 | Network kernel parameters | Enforced, with per-host deviations | All rules enforced. Forwarding and no `log_martians` on container hosts; see [3-network.md](controls/3-network.md). |
| 4.1 | Host firewall (ufw) | Replaced *(proposed)* | firewalld via `puppet/firewalld`. |
| 5.1 | SSH server | Planned | Has to work with the existing 2FA setup. |
| 5.2 | Privilege escalation (sudo, su) | Planned | |
| 5.3 | PAM | Planned | `common-*` files are hand-edited; `pam-auth-update` profiles (5.3.2) may be replaced by managed files. |
| 5.4 | User accounts and environment | Planned | |
| 6.1 | System logging (journald, rsyslog, log files) | Planned | |
| 6.2 | System auditing (auditd) | Replaced | Wazuh. _TODO: will auditd rules still be deployed as a Wazuh data source?_ |
| 6.3 | Integrity checking (AIDE) | Replaced | Wazuh file integrity monitoring. |
| 7.1 | System file and directory access | Partial *(proposed)* | Identity-file permissions enforced; world-writable, unowned, and SUID/SGID review monitored by SCA. |
| 7.2 | Local user and group settings | Monitored *(proposed)* | Wazuh SCA checks; home directory permissions may be enforced. |

## Rule-level deviations

Individual recommendations that depart from CIS inside a section that's
otherwise enforced (a different value, a per-role exception, and so on).

| CIS | Recommendation | CIS expects | Baseline does | Rationale |
|---|---|---|---|---|
| 1.1.2.1.4 | `/tmp` noexec | `noexec` on `/tmp` | `/tmp` stays executable | apt scripts; [1-initial-setup.md](controls/1-initial-setup.md#11214-tmp-is-not-mounted-noexec) |
| 1.1.1.11 | Unused filesystem modules | `squashfs` not loadable | `squashfs` loadable fleet-wide; `nfsd` allowed on NFS servers | [1-initial-setup.md](controls/1-initial-setup.md#deviations) |
| 3.3.1.1–3.3.1.3, 3.3.2.1–3.3.2.2 | IP forwarding | disabled | enabled on container hosts and K3s nodes | Router exception; [3-network.md](controls/3-network.md#deviations) |
| 3.3.1.16–3.3.1.17 | log_martians | `1` | `0` on forwarding hosts | [3-network.md](controls/3-network.md#deviations) |

## Rationale

One subsection for each Replaced, N/A, Omitted, or Partial entry above, so
each departure has its reasoning written down.

### 1.1.2 Filesystem partitions

Hosts are installed with a single root filesystem. Separate partitions are
Level 2 and not adopted, so the mount-option rules for paths that live on `/`
are N/A. `/tmp`, `/dev/shm` and `/var/tmp` are tmpfs mounts managed by
`baseline::mounts`. Per-path detail is in
[1-initial-setup.md](controls/1-initial-setup.md#deviations).

### 1.7 GNOME Display Manager

Every host is a headless server; nothing in the fleet runs GDM or any other
display manager, so none of the 1.7 rules apply.

### 2.1 Server services

_TODO_

### 3.3 Network kernel parameters

See the deviations in [3-network.md](controls/3-network.md#deviations).

### 4.1 Host firewall: firewalld instead of ufw

_TODO_

### 6.2 System auditing: Wazuh instead of the CIS auditd rule set

_TODO_

### 6.3 Integrity checking: Wazuh FIM instead of AIDE

_TODO_

### 7.1 / 7.2 Report-only checks

_TODO_
