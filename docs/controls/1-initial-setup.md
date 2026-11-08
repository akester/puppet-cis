# 1 Initial Setup

Controls from chapter 1 of the CIS Debian Linux 13 Benchmark v1.1.0. The
section-level status is in [cis-coverage.md](../cis-coverage.md).

## Controls

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

### Filesystem partitions (1.1.2)

`baseline::mounts` writes tmpfs entries to `/etc/fstab` for `/tmp`, `/var/tmp`
and `/dev/shm`, and mounts them (or remounts them when the options change).
`baseline::manage_mounts => false` turns the class off.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-mount-001 | 1.1.2.1.1 | `/tmp` is a tmpfs | `size=1G` | Enforced | `baseline::mounts::tmp_size` | The fstab entry takes precedence over systemd's `tmp.mount`, which is left alone (masked or not). |
| hl-mount-002 | 1.1.2.1.2 | `/tmp` mount option | `nodev` | Enforced | `baseline::manage_mounts` |  |
| hl-mount-003 | 1.1.2.1.3 | `/tmp` mount option | `nosuid` | Enforced | `baseline::manage_mounts` |  |
| — | 1.1.2.1.4 | `/tmp` mount option | no `noexec` | Omitted | — | apt scripts run from `/tmp`; see below. |
| hl-mount-004 | 1.1.2.2.1 | `/dev/shm` is a tmpfs | no size limit | Enforced | `baseline::manage_mounts` | systemd already mounts it; the fstab entry pins the options. Size is the tmpfs default (half of RAM). |
| hl-mount-005 | 1.1.2.2.2 | `/dev/shm` mount option | `nodev` | Enforced | `baseline::manage_mounts` |  |
| hl-mount-006 | 1.1.2.2.3 | `/dev/shm` mount option | `nosuid` | Enforced | `baseline::manage_mounts` |  |
| hl-mount-007 | 1.1.2.2.4 | `/dev/shm` mount option | `noexec` | Enforced | `baseline::manage_mounts` | Not the systemd default; added by the fstab entry. |
| — | 1.1.2.3.1 | Separate `/home` partition | — | Omitted | — | Level 2. `/home` is on `/`. |
| — | 1.1.2.3.2 | `/home` mount option | `nodev` | N/A | — | Only applies to a separate `/home`; see below. |
| — | 1.1.2.3.3 | `/home` mount option | `nosuid` | N/A | — | Only applies to a separate `/home`; see below. |
| — | 1.1.2.4.1 | Separate `/var` partition | — | Omitted | — | Level 2. `/var` is on `/`. |
| — | 1.1.2.4.2 | `/var` mount option | `nodev` | N/A | — | Only applies to a separate `/var`; see below. |
| — | 1.1.2.4.3 | `/var` mount option | `nosuid` | N/A | — | Only applies to a separate `/var`; see below. |
| hl-mount-008 | 1.1.2.5.1 | `/var/tmp` is a separate mount | tmpfs, no size limit | Enforced | `baseline::manage_mounts` | **Level 2**; kept as an addition. Contents don't survive a reboot; see below. |
| hl-mount-009 | 1.1.2.5.2 | `/var/tmp` mount option | `nodev` | Enforced | `baseline::manage_mounts` |  |
| hl-mount-010 | 1.1.2.5.3 | `/var/tmp` mount option | `nosuid` | Enforced | `baseline::manage_mounts` |  |
| hl-mount-011 | 1.1.2.5.4 | `/var/tmp` mount option | `noexec` | Enforced | `baseline::manage_mounts` |  |
| — | 1.1.2.6.1 | Separate `/var/log` partition | — | Omitted | — | Level 2. `/var/log` is on `/`. |
| — | 1.1.2.6.2 | `/var/log` mount option | `nodev` | N/A | — | Only applies to a separate `/var/log`; see below. |
| — | 1.1.2.6.3 | `/var/log` mount option | `nosuid` | N/A | — | Only applies to a separate `/var/log`; see below. |
| — | 1.1.2.6.4 | `/var/log` mount option | `noexec` | N/A | — | Only applies to a separate `/var/log`; see below. |
| — | 1.1.2.7.1 | Separate `/var/log/audit` partition | — | Omitted | — | Level 2. `/var/log/audit` is on `/`. |
| — | 1.1.2.7.2 | `/var/log/audit` mount option | `nodev` | N/A | — | Only applies to a separate `/var/log/audit`; see below. |
| — | 1.1.2.7.3 | `/var/log/audit` mount option | `nosuid` | N/A | — | Only applies to a separate `/var/log/audit`; see below. |
| — | 1.1.2.7.4 | `/var/log/audit` mount option | `noexec` | N/A | — | Only applies to a separate `/var/log/audit`; see below. |

### Package repositories (1.2.1)

Apt sources are site-specific and stay in the control repo (`base::apt_cache`
for the distro sources, `apt::source` in each service module for the rest).
The baseline doesn't manage them. `baseline::apt` sets ownership and mode on
the key directories (not their contents) and writes the repository security
settings to `/etc/apt/apt.conf.d/99-baseline`, read last so it overrides
earlier drop-ins. `baseline::manage_apt => false` turns it off.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| — | 1.2.1.1 | Sources use `Signed-By` | — | Replaced | — | Control repo: every Puppet-managed source sets `Signed-By`; see below. |
| — | 1.2.1.2 | Weak dependencies | — | Omitted | — | Level 2. |
| — | 1.2.1.3 | apt key file ownership and mode | root:root, `0644` or tighter | Monitored | — | Wazuh SCA. |
| hl-apt-001 | 1.2.1.4 | `/etc/apt/trusted.gpg.d` ownership and mode | root:root `0755` | Enforced | `baseline::manage_apt` | Directory only. |
| — | 1.2.1.5 | `/etc/apt/auth.conf.d` ownership and mode | root:root, `0755` or tighter | Monitored | — | puppetlabs/apt declares this directory; see below. |
| — | 1.2.1.6 | Files in `/etc/apt/auth.conf.d` | root:root, `0640` or tighter | Monitored | — | Empty by default; Wazuh SCA. |
| hl-apt-002 | 1.2.1.7 | `/usr/share/keyrings` ownership and mode | root:root `0755` | Enforced | `baseline::manage_apt` | Directory only. |
| — | 1.2.1.8 | `/etc/apt/sources.list.d` ownership and mode | root:root, `0755` or tighter | Monitored | — | puppetlabs/apt declares this directory; see below. |
| — | 1.2.1.9 | Files in `/etc/apt/sources.list.d` | root:root `0644` | Monitored | — | `apt::source` writes them root:root `0644`; Wazuh SCA. |
| — | 1.2.1.10 | `sources.list` uses https | — | Monitored | — | `sources.list` is only a comment; Wazuh SCA. |
| — | 1.2.1.11 | `sources.list.d` uses https | — | Monitored | — | Sources point at `https://apt.kester.cloud`; Wazuh SCA. |
| hl-apt-003 | 1.2.1.12 | `Acquire::AllowInsecureRepositories` | `0` | Enforced | `baseline::manage_apt` | Already the apt default; set so it can't drift. |
| hl-apt-004 | 1.2.1.13 | `Acquire::AllowWeakRepositories` | `0` | Enforced | `baseline::manage_apt` | Already the apt default. |
| hl-apt-005 | 1.2.1.14 | `Acquire::AllowDowngradeToInsecureRepositories` | `0` | Enforced | `baseline::manage_apt` | Already the apt default. |
| hl-apt-006 | 1.2.1.15 | `Acquire::Check-Date` | `true` | Enforced | `baseline::manage_apt` | Already the apt default. |

### Package updates (1.2.2)

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| — | 1.2.2.1 | Updates and patches installed | — | Replaced | — | Control repo: `base::unattended` runs unattended-upgrades daily. Its allow list has to include the site's own repositories, so it stays there. |

### AppArmor (1.3.1)

`baseline::apparmor` installs the userspace packages
(`baseline::manage_apparmor => false` turns it off). The 1.3.1.4 sysctl is
written by `baseline::sysctl`, like the 1.5 ones.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-apparmor-001 | 1.3.1.1 | `apparmor` package | installed | Enforced | `baseline::manage_apparmor` | Part of the default Debian 13 install. |
| hl-apparmor-002 | 1.3.1.1 | `apparmor-utils` package | installed | Enforced | `baseline::manage_apparmor` | Not installed by default; the baseline adds it. |
| — | 1.3.1.2 | AppArmor enabled at boot | — | Monitored | — | On by default in the Debian kernel; Wazuh SCA. |
| — | 1.3.1.3 | All AppArmor profiles enforcing | — | Omitted | — | Level 2. |
| hl-sysctl-037 | 1.3.1.4 | `kernel.apparmor_restrict_unprivileged_unconfined` | `1` | Enforced | `baseline::manage_sysctl` | Stops unprivileged, unconfined processes from using `aa-exec` to switch to a more permissive profile. The key exists on the Debian 13 kernel. Skipped where AppArmor isn't active (Raspberry Pi kernel). |

### Bootloader (1.4)

`baseline::bootloader` manages the GRUB config's ownership and mode
(`baseline::manage_bootloader => false` turns it off).

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| — | 1.4.1 | Bootloader password | — | Omitted | — | See below. |
| hl-boot-001 | 1.4.2 | `/boot/grub/grub.cfg` ownership and mode | root:root `0600` | Enforced | `baseline::manage_bootloader` | Only where the file exists. update-grub resets the mode; the next run fixes it. |

### Additional process hardening (1.5)

Sysctl controls are written to `/etc/sysctl.d/60-baseline.conf` and applied
to the running kernel (`baseline::sysctl`). `manage_sysctl => false` turns
the whole set off, e.g. in LXC containers.
`baseline::process` removes the packages 1.5 rules out and turns off core
dumps with two drop-ins: `/etc/security/limits.d/60-baseline.conf` and
`/etc/systemd/coredump.conf.d/60-baseline.conf`
(`baseline::manage_process => false` turns it off).

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-sysctl-001 | 1.5.1 | `fs.protected_hardlinks` | `1` | Enforced | `baseline::manage_sysctl` | Already the Debian default; managed so it can't drift. |
| hl-sysctl-002 | 1.5.2 | `fs.protected_symlinks` | `1` | Enforced | `baseline::manage_sysctl` | **Level 2** in CIS; kept as an addition because it's the Debian default anyway. |
| hl-sysctl-003 | 1.5.3 | `kernel.yama.ptrace_scope` | `2` | Enforced | `baseline::sysctl::ptrace_scope` (1–2) | Debian ships `0`. CIS accepts 1, 2 or 3; see below. Skipped where Yama isn't active (Raspberry Pi kernel). |
| hl-sysctl-004 | 1.5.4 | `fs.suid_dumpable` | `0` | Enforced | `baseline::manage_sysctl` | Kernel default is `0`, but systemd-coredump's `50-coredump.conf` sets `2`; the baseline drop-in (`60-`) loads later and wins. Carried over from os_hardening. |
| hl-sysctl-005 | 1.5.5 | `kernel.dmesg_restrict` | `1` | Enforced | `baseline::manage_sysctl` | Already the Debian kernel default; managed so it can't drift. |
| hl-process-001 | 1.5.6 | `prelink` package | purged | Enforced | `baseline::manage_process` | No trixie package (apt doesn't know it); keeps it from coming back. |
| hl-process-002 | 1.5.7 | `apport` package | purged | Enforced | `baseline::manage_process` | No install candidate on trixie. CIS also accepts `enabled=0`; purging covers both checks. |
| hl-sysctl-006 | 1.5.8 | `kernel.kptr_restrict` | `1` | Enforced | `baseline::manage_sysctl` | Hides `/proc/kallsyms` and similar addresses from users without `CAP_SYSLOG`. |
| hl-sysctl-007 | 1.5.9 | `kernel.randomize_va_space` | `2` | Enforced | `baseline::manage_sysctl` | Already the kernel default. Carried over from os_hardening. |
| hl-process-003 | 1.5.10 | Core file size limit | `* hard core 0` | Enforced | `baseline::manage_process` | pam_limits; applies to login sessions, not systemd services or root. See below. |
| hl-process-004 | 1.5.11 | systemd-coredump `ProcessSizeMax` | `0` | Enforced | `baseline::manage_process` | Written even where systemd-coredump isn't installed. |
| hl-process-005 | 1.5.12 | systemd-coredump `Storage` | `none` | Enforced | `baseline::manage_process` |  |
| hl-sysctl-035 | — | `kernel.sysrq` | `0` | Enforced | `baseline::manage_sysctl` | Not CIS. Debian ships `438`. Carried over from os_hardening; see below. |

### Warning banners (1.6)

`baseline::banners` writes the warning text to `/etc/issue` (local console)
and `/etc/issue.net` (remote logins), and empties `/etc/motd`. Moved from
`harden::rules::banners` in the control repo.
`baseline::manage_banners => false` turns it off.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-banner-001 | 1.6.1 | `/etc/motd` content | empty | Enforced | `baseline::manage_banners` | No system information. |
| hl-banner-002 | 1.6.2 | `/etc/issue` content | warning text | Enforced | `baseline::banners::banner` | Getty escapes (`\m`, `\r`, `\s`, `\v`) are refused at compile time. |
| hl-banner-003 | 1.6.3 | `/etc/issue.net` content | warning text | Enforced | `baseline::banners::banner` | Same text as `/etc/issue`. |
| hl-banner-007 | 1.6.4 | pam_motd shows no system information | `/etc/update-motd.d/10-uname` absent | Enforced | `baseline::manage_banners` | Debian's sshd and login PAM show `/run/motd.dynamic`, rebuilt at each login; `10-uname` put `uname -snrvm` in it. |
| — | 1.6.5 | sshd `Banner` | — | Monitored | — | Set by the site SSH config in the control repo; Wazuh SCA. |
| hl-banner-004 | 1.6.6 | `/etc/motd` ownership and mode | root:root `0644` | Enforced | `baseline::manage_banners` |  |
| hl-banner-005 | 1.6.7 | `/etc/issue` ownership and mode | root:root `0644` | Enforced | `baseline::manage_banners` |  |
| hl-banner-006 | 1.6.8 | `/etc/issue.net` ownership and mode | root:root `0644` | Enforced | `baseline::manage_banners` |  |
| hl-banner-008 | 1.6.9 | `/run/motd.dynamic` ownership and mode | root:root `0644` | Enforced | `baseline::manage_banners` | The `motd=` file in Debian's sshd and login PAM. Rewritten at each login; managed only where it exists. |
| — | 1.6.10 | sshd banner file ownership and mode | — | Monitored | — | Site SSH config in the control repo; Wazuh SCA. |
| hl-banner-009 | 1.6.11 | `update-notifier-motd.service` | stopped, masked | Enforced | `baseline::manage_banners` | Ubuntu only; Debian doesn't ship update-notifier. |
| hl-banner-010 | 1.6.12 | `update-notifier-motd.timer` | stopped, masked | Enforced | `baseline::manage_banners` | Ubuntu only. |

### GNOME Display Manager (1.7)

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| — | 1.7.1–1.7.6 | GDM settings | — | N/A | — | No GDM (or any desktop) installed anywhere in the fleet. |
| — | 1.7.7 | Xwayland | — | Omitted | — | Level 2, and N/A for the same reason. |

## Deviations

### 1.1.2.3, 1.1.2.4, 1.1.2.6, 1.1.2.7: /home and /var are not separate partitions

Separate partitions for `/home`, `/var`, `/var/log` and `/var/log/audit`
(1.1.2.x.1) are Level 2, and fleet hosts keep all of them on the root
filesystem. Their mount-option rules (`nodev`, `nosuid`, and `noexec` for the
log paths) are Level 1 but only apply to a separate partition; setting them on
`/` would break the system. They are N/A here, and the baseline does not check
for or manage these mounts. `/var/tmp` (1.1.2.5) is different: it is a tmpfs
managed by `baseline::mounts`.

### hl-mount-008: /var/tmp as a tmpfs

CIS's separate `/var/tmp` partition (1.1.2.5.1) is Level 2 and assumes a disk
partition. The baseline mounts a tmpfs instead, as `harden::rules::devs` did
before it. That's opinionated: `/var/tmp` is meant to survive reboots, and
here it doesn't, so nothing on these hosts should rely on files kept there.
It makes the Level 1 option rules (1.1.2.5.2 to 1.1.2.5.4) apply without
repartitioning. The size is the tmpfs default, half of RAM.

### 1.2.1.1: Signed-By in the control repo

The upstream, site-specific repo we use manages the apt sources for all managed
packages, host packages, and vendor packages like Proxmox.  All utilize the
`apt::source` resource type with a specific key or `signed-by` parameter that
sets the `Signed-by` setting for each software source.

### 1.2.1.5, 1.2.1.8: auth.conf.d and sources.list.d are monitored

puppetlabs/apt (included by the control repo on every Debian 13 host)
already declares both directories, root-owned but without a mode, so the
baseline can't declare them without a duplicate resource. The package ships
them root:root `0755`, and the Wazuh check catches any drift.

### 1.4.1: no bootloader password

A GRUB password stops someone at the console from editing the boot entry,
e.g. booting into single-user mode to get past access controls. It doesn't
add much here:

- **Physical hosts** are kept on site only, so console access already means
  physical access.
- **VMs** can only be reached at the console through the Proxmox control
  plane. Someone who has compromised that doesn't need the bootloader: they
  can mount the VM's disks directly or swap its boot media and read or change
  anything on them.

Omitted for now. Revisit if a host ends up somewhere with untrusted physical
access.

### 1.1.2.1.4: /tmp is not mounted noexec

CIS Level 1 wants `noexec` on `/tmp`. Many apt maintainer scripts and
third-party installers write executables to `/tmp` and run them, and fail
under `noexec`. Re-pointing them all (`APT::ExtractTemplates::TempDir`,
`TMPDIR` for every installer) isn't worth the breakage, so `/tmp` stays
executable. `nodev` and `nosuid` still apply. The Wazuh check will need an
exception.

### hl-process-003..005: core dumps

The `* hard core 0` limit comes from pam_limits, so it only covers PAM
sessions (SSH, console, `su`, `sudo`), and pam_limits never applies a `*`
entry to root. Services started by systemd don't go through PAM. For
everything else, the kernel hands crashes to systemd-coredump where it's
installed, and `ProcessSizeMax=0` with `Storage=none` makes it log the crash
without keeping a dump. `fs.suid_dumpable=0` (hl-sysctl-004) also stops
setuid programs from dumping.

### hl-sysctl-003: ptrace_scope 2

`2` means only processes with `CAP_SYS_PTRACE` (in practice root) can attach
with ptrace. Non-root `gdb -p` and `strace -p` stop working, as does
debugging inside Docker containers unless they run with
`--cap-add SYS_PTRACE`. Yama isn't namespaced, so on a container host this
applies to every container on it. Hosts that need non-root debugging set
`baseline::sysctl::ptrace_scope: 1` in Hiera. `3` is not allowed because it
can't be lowered again without a reboot.

### hl-sysctl-003, hl-sysctl-037: kernels without Yama or AppArmor

Yama and AppArmor only register their sysctls while the security module is
active. The Raspberry Pi kernel runs without them, so the keys don't exist
and setting them fails. The `baseline_lsm` fact reads the active modules from
`/sys/kernel/security/lsm`, and `baseline::sysctl` leaves out a key when its
module isn't listed. Those hosts don't meet 1.5.3 or 1.3.1.4, and there's no
setting that would fix that short of a kernel with the module enabled. If the
fact is missing, both keys are managed as usual.

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

