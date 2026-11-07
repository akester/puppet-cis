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

### Kernel modules (1.1.1)

Kernel module controls are written to `/etc/modprobe.d/60-baseline.conf` by
`baseline::kmod`: `install <module> /bin/false` plus `blacklist <module>`.
Modules already loaded are not unloaded; the block takes full effect at the
next boot. `baseline::kmod::allow` exempts listed modules on a host, and
`baseline::manage_kmod => false` turns the class off.

| ID | CIS | Module | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-kmod-001 | 1.1.1.1 | `cramfs` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-002 | 1.1.1.2 | `freevxfs` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-003 | 1.1.1.3 | `hfs` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-004 | 1.1.1.4 | `hfsplus` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-005 | 1.1.1.5 | `jffs2` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| — | 1.1.1.6 | `overlay` | — | Omitted | — | Level 2. Docker and K3s need it. |
| — | 1.1.1.7 | `squashfs` | Loadable | Omitted | — | Level 2. Also left out of hl-kmod-014 by choice; see below. |
| — | 1.1.1.8 | `udf` | Not loadable | Enforced | `baseline::kmod::allow` | Level 2 rule, but blocked anyway by hl-kmod-014. |
| hl-kmod-006 | 1.1.1.9 | `firewire-core` | Not loadable | Enforced | `baseline::manage_kmod` |  |
| hl-kmod-007 | 1.1.1.10 | `usb-storage` | Not loadable | Enforced | `baseline::kmod::allow` | Hosts that need USB disks allow it; see below. |
| hl-kmod-014 | 1.1.1.11 | Unused filesystem modules | Not loadable | Enforced | `baseline::kmod::allow` | Fixed list from the Debian 13 kernel; mounted filesystems are never denied. See below. |

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

### hl-kmod-007: usb-storage

Blocked by default, as CIS Level 1 asks. VMs have no USB disks. A physical
host that needs one (backups, installs) sets `baseline::kmod::allow:
['usb-storage']` in Hiera.

### 1.1.1.6: overlay

Level 2, and out of scope: Docker and K3s need `overlay`. 1.1.1.7 (`squashfs`)
and 1.1.1.8 (`udf`) are Level 2 too. The Level 1 catch-all (hl-kmod-014)
blocks `udf` anyway; `squashfs` is deliberately left loadable fleet-wide.

### hl-kmod-014: unused filesystem modules (1.1.1.11)

CIS asks for every filesystem module in `kernel/fs/` that isn't needed to be
denied. Its audit checks modules one directory deep under `kernel/fs/*/` and
skips `nls`. The baseline uses a fixed list built from the Debian 13 kernel
(6.12), rather than working it out from what's mounted on each run, so a
filesystem that is only mounted now and then (an ISO, a USB backup) isn't
locked out when it's unmounted.

Left loadable, because the fleet uses them:

| Module | Why |
|---|---|
| `ext4`, `jbd2` | Root and `/boot`. `ext4` also mounts ext2 (`CONFIG_EXT4_USE_FOR_EXT2`). |
| `fat`, `vfat` | EFI system partition. |
| `isofs` | cloud-init seed drives and install media. |
| `efivarfs`, `autofs4`, `configfs` | Mounted by systemd. |
| `overlay` | Docker and K3s (1.1.1.6). |
| `squashfs` | Kept by choice. A deviation from 1.1.1.11; the Wazuh check will need an exception. |
| `nfs`, `nfsv3`, `nfsv4`, `lockd`, `grace`, `nfs_acl`, `netfs` | NFS client mounts. |

Everything else is denied, including `xfs`, `btrfs`, `cifs`, `nfsd`, `9p` and
`vboxsf`. A host that needs one lists it in `baseline::kmod::allow`. The NFS servers
need `nfsd` allowed this way (see [migration.md](../migration.md)). `ksmbd` (the in-kernel SMB server) is denied too;
Samba's `smbd` doesn't use it.

**Mounted filesystems are never denied.** CIS warns that denying an in-use
filesystem may be fatal: denying the root filesystem's module makes the host
unbootable once the initramfs is rebuilt. The class reads the `mountpoints`
fact, leaves out any module for a mounted filesystem type, and logs a Puppet
warning naming it. The fix is to add it to `allow`.

When the kernel moves to a new major version, check `kernel/fs/` for new
modules.

### Module rules and the initramfs

modprobe.d files are copied into the initramfs when it's rebuilt. Until the
next `update-initramfs` (e.g. on a kernel update), early boot uses the old
rules. None of these modules are needed at early boot, so the baseline doesn't
force a rebuild.

