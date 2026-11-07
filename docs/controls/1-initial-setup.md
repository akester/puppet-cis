# 1 Initial Setup

Controls from chapter 1 of the CIS Debian Linux 13 Benchmark v1.1.0. The
section-level status is in [cis-coverage.md](../cis-coverage.md).

## Controls

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-sysctl-037 | 1.3.1.4 | `kernel.apparmor_restrict_unprivileged_unconfined` | `1` | Enforced | `baseline::manage_sysctl` | Stops unprivileged, unconfined processes from using `aa-exec` to switch to a more permissive profile. The key exists on the Debian 13 kernel. |
| hl-sysctl-001 | 1.5.1 | `fs.protected_hardlinks` | `1` | Enforced | `baseline::manage_sysctl` | Already the Debian default; managed so it can't drift. |
| hl-sysctl-002 | 1.5.2 | `fs.protected_symlinks` | `1` | Enforced | `baseline::manage_sysctl` | **Level 2** in CIS; kept as an addition because it's the Debian default anyway. |
| hl-sysctl-003 | 1.5.3 | `kernel.yama.ptrace_scope` | `2` | Enforced | `baseline::sysctl::ptrace_scope` (1–2) | Debian ships `0`. CIS accepts 1, 2 or 3; see below. |
| hl-sysctl-004 | 1.5.4 | `fs.suid_dumpable` | `0` | Enforced | `baseline::manage_sysctl` | Kernel default is `0`, but systemd-coredump's `50-coredump.conf` sets `2`; the baseline drop-in (`60-`) loads later and wins. Carried over from os_hardening. |
| hl-sysctl-005 | 1.5.5 | `kernel.dmesg_restrict` | `1` | Enforced | `baseline::manage_sysctl` | Already the Debian kernel default; managed so it can't drift. |
| hl-sysctl-006 | 1.5.8 | `kernel.kptr_restrict` | `1` | Enforced | `baseline::manage_sysctl` | Hides `/proc/kallsyms` and similar addresses from users without `CAP_SYSLOG`. |
| hl-sysctl-007 | 1.5.9 | `kernel.randomize_va_space` | `2` | Enforced | `baseline::manage_sysctl` | Already the kernel default. Carried over from os_hardening. |
| hl-sysctl-035 | — | `kernel.sysrq` | `0` | Enforced | `baseline::manage_sysctl` | Not CIS. Debian ships `438`. Carried over from os_hardening; see below. |

Sysctl controls are written to `/etc/sysctl.d/60-baseline.conf` and applied
to the running kernel (`baseline::sysctl`). `manage_sysctl => false` turns
the whole set off, e.g. in LXC containers.

## Deviations

### hl-sysctl-003: ptrace_scope 2

`2` means only processes with `CAP_SYS_PTRACE` (in practice root) can attach
with ptrace. Non-root `gdb -p` and `strace -p` stop working, as does
debugging inside Docker containers unless they run with
`--cap-add SYS_PTRACE`. Yama isn't namespaced, so on a container host this
applies to every container on it. Hosts that need non-root debugging set
`baseline::sysctl::ptrace_scope: 1` in Hiera. `3` is not allowed because it
can't be lowered again without a reboot.

### hl-sysctl-035: kernel.sysrq 0 (not CIS)

Turns off the magic SysRq key combinations, which can sync, remount
read-only, kill tasks or reboot without a login. Anyone at a console can send
them, including the Proxmox VM console, serial consoles and IPMI/BMC remote
consoles. Root can still use `/proc/sysrq-trigger`, which this setting doesn't
affect. The fleet already runs `0` under os_hardening.
