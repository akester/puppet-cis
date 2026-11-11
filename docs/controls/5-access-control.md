# 5 Access Control

Controls from chapter 5 of the CIS Debian Linux 13 Benchmark v1.1.0. The
section-level status is in [cis-coverage.md](../cis-coverage.md).

## Controls

### SSH server (5.1)

`baseline::ssh` installs openssh-server, writes `/etc/ssh/sshd_config`, and
keeps `ssh` running (`baseline::manage_ssh => false` turns it off). Other
parameters: `ports` (default `[22]`) and `password_authentication` (default
`true`, not a CIS rule).

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-ssh-001 | 5.1.1 | `/etc/ssh/sshd_config` ownership and mode | root:root `0600` | Enforced | `baseline::manage_ssh` | The whole file is managed and checked with `sshd -t` before it's written. It has no `Include`; see below. |
| hl-ssh-002 | 5.1.2 | `/etc/ssh/sshd_config.d` ownership and mode | root:root `0700`, files `0600` | Enforced | `baseline::manage_ssh` | The files in it get 5.1.1's mode too. sshd doesn't read them. |
| hl-ssh-003 | 5.1.3 | Private host keys | root:root `0600` | Enforced | `baseline::manage_ssh` | The ed25519 and RSA keys sshd uses. Only where they exist. |
| hl-ssh-004 | 5.1.4 | Public host keys | root:root `0644` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-005 | 5.1.5 | `AllowGroups` | `sudo ssh` | Enforced | `baseline::ssh::allow_groups` | The control repo creates the `ssh` group. |
| hl-ssh-006 | 5.1.6 | `Banner` | `/etc/issue.net` | Enforced | `baseline::manage_ssh` | The file comes from `baseline::banners`. Covers 1.6.5 too. |
| hl-ssh-007 | 5.1.7 | `Ciphers` | chacha20-poly1305, aes256/128-gcm, aes256-ctr | Enforced | `baseline::manage_ssh` | An explicit list, rather than CIS's subtractive form. |
| hl-ssh-008 | 5.1.8 | `ClientAliveInterval`, `ClientAliveCountMax` | `300`, `2` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-009 | 5.1.9 | `DisableForwarding` | `yes` | Enforced | `baseline::ssh::disable_forwarding` | `X11Forwarding no` stays set when this is turned off. Off on remote development hosts; see below. |
| hl-ssh-010 | 5.1.10 | `GSSAPIAuthentication` | `no` | Enforced | `baseline::manage_ssh` | Already Debian's default; now explicit. |
| hl-ssh-011 | 5.1.11 | `HostbasedAuthentication` | `no` | Enforced | `baseline::manage_ssh` | Already Debian's default; now explicit. |
| hl-ssh-012 | 5.1.12 | `IgnoreRhosts` | `yes` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-013 | 5.1.13 | `KexAlgorithms` | sntrup761x25519, curve25519, DH group exchange (SHA-256) | Enforced | `baseline::manage_ssh` | An explicit list with nothing weak. |
| hl-ssh-014 | 5.1.14 | Post-quantum key exchange | `mlkem768x25519-sha256` and `sntrup761x25519-sha512` | Enforced | `baseline::manage_ssh` | mlkem only on OpenSSH 9.9 and later (the `baseline_openssh_version` fact); sshd rejects it on older releases such as Ubuntu 24.04's 9.6. |
| hl-ssh-015 | 5.1.15 | `LoginGraceTime` | `30` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-016 | 5.1.16 | `LogLevel` | `VERBOSE` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-017 | 5.1.17 | `MACs` | hmac-sha2-512/256-etm | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-018 | 5.1.18 | `MaxAuthTries` | `3` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-019 | 5.1.19 | `MaxSessions` | `2` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-020 | 5.1.20 | `MaxStartups` | `10:30:60` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-021 | 5.1.21 | `PermitEmptyPasswords` | `no` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-022 | 5.1.22 | `PermitRootLogin` | `no` | Enforced | `baseline::ssh::permit_root_login` | `yes` on Proxmox hosts; see below. |
| hl-ssh-023 | 5.1.23 | `PermitUserEnvironment` | `no` | Enforced | `baseline::manage_ssh` |  |
| hl-ssh-024 | 5.1.24 | `UsePAM` | `yes` | Enforced | `baseline::manage_ssh` |  |

### Privilege escalation (5.2)

`baseline::sudo` installs sudo, writes `/etc/sudoers`, and limits `su` to root
(`baseline::manage_sudo => false` turns it off). `/etc/sudoers` is checked with
`visudo -c` before it's written and still includes `/etc/sudoers.d`, where the
control repo puts its grants (`base::sudo_entry`).

Debian 13 keeps classic sudo. Its `sudo-rs` package installs alongside as
`sudo-rs` and doesn't replace `sudo`. On Ubuntu 25.10 and later, where sudo-rs
is `sudo`, the `logfile` line is left out and sudo logs to syslog only.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-sudo-001 | 5.2.1 | sudo installed | `sudo` | Enforced | `baseline::manage_sudo` |  |
| hl-sudo-002 | 5.2.2 | `Defaults use_pty` | set | Enforced | `baseline::manage_sudo` |  |
| hl-sudo-003 | 5.2.3 | `Defaults logfile` | `/var/log/sudo.log` | Enforced | `baseline::manage_sudo` | Rotated daily, five kept (`/etc/logrotate.d/sudo`). |
| — | 5.2.4 | No `NOPASSWD` | — | Omitted | — | Level 2. Service grants in `sudoers.d` use `NOPASSWD`. |
| hl-sudo-004 | 5.2.5 | No `!authenticate` | not set | Enforced | `baseline::manage_sudo` | Not in `/etc/sudoers`; `base::sudo_entry` can't write it. |
| hl-sudo-005 | 5.2.6 | `Defaults timestamp_timeout` | `15` | Enforced | `baseline::sudo::timestamp_timeout` | 0 to 15. |
| hl-sudo-006 | 5.2.7 | `su` restricted | `pam_wheel.so use_uid group=sugroup` | Enforced | `baseline::manage_sudo` | `sugroup` is empty, so only root can `su`; use `sudo -i` instead. |

### PAM (5.3)

`baseline::pam` (`baseline::manage_pam => false` turns it off) never edits
`/etc/pam.d/common-*`. pam-auth-update builds those from the profiles in
`/usr/share/pam-configs`, and stops updating any it finds locally modified. The
baseline manages the profiles and the modules' own config files instead.

#### Packages (5.3.1)

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-pam-001 | 5.3.1.1 | `libpam-runtime` | installed | Enforced | `baseline::manage_pam` | Kept current by unattended-upgrades (control repo, CIS 1.2.2), not Puppet. |
| hl-pam-002 | 5.3.1.2 | `libpam-modules` | installed | Enforced | `baseline::manage_pam` | As above. |
| hl-pam-003 | 5.3.1.3 | `libpam-pwquality` | installed | Enforced | `baseline::manage_pam` | As above. Its install enables the `pwquality` profile with the module's defaults until 5.3.3.2 sets them. |
| hl-pam-004 | 5.3.1.4 | `cracklib-runtime` | installed | Enforced | `baseline::manage_pam` | As above. |

#### pam-auth-update profiles (5.3.2)

The baseline writes the `faillock`, `faillock_notify` and `pwhistory` profiles
as CIS gives them; `unix` and `pwquality` come with their packages. When a
profile or one of the packages changes, `pam-auth-update --enable` turns on all
five and rewrites `common-*`. It runs without prompts and keeps any local
changes to `common-*` rather than forcing over them. It only runs on a change,
so a profile disabled by hand afterwards stays off until the next change; the
Wazuh checks catch that.

Profiles with the same priority are ordered in reverse name order, so
`pwquality` comes before `pwhistory`, whose `use_authtok` takes the password
pwquality has already checked.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-pam-005 | 5.3.2.1 | `unix` profile | enabled | Enforced | `baseline::manage_pam` | Enabled by default; the baseline re-enables it with the others. |
| hl-pam-006 | 5.3.2.2 | `faillock`, `faillock_notify` profiles | enabled | Enforced | `baseline::manage_pam` | Values in `/etc/security/faillock.conf` (5.3.3.1). |
| hl-pam-007 | 5.3.2.3 | `pwquality` profile | enabled | Enforced | `baseline::manage_pam` | Shipped by `libpam-pwquality`. |
| hl-pam-008 | 5.3.2.4 | `pwhistory` profile | enabled, `use_authtok` | Enforced | `baseline::manage_pam` | Options are in `/etc/security/pwhistory.conf` (5.3.3.3), which CIS prefers to arguments on the line. |

#### pam_faillock (5.3.3.1)

`/etc/security/faillock.conf` is managed whole. The profiles pass pam_faillock
no arguments, so its values apply. `faillock --user <name> --reset` unlocks an
account early. Key-based SSH logins don't go through the PAM auth stack, so
they're never counted or locked out.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-pam-009 | 5.3.3.1.1 | `deny` | `5` | Enforced | `baseline::pam::faillock_deny` | 1 to 5. |
| hl-pam-010 | 5.3.3.1.2 | `unlock_time` | `900` | Enforced | `baseline::pam::faillock_unlock_time` | 0 (never) or 900 to 604800 seconds. |
| — | 5.3.3.1.3 | Lockout includes root | — | Omitted | — | Level 2. Root stays exempt, so a lockout can't shut out the console. |

#### pam_pwquality (5.3.3.2)

The values are in `/etc/security/pwquality.conf.d/50-baseline.conf`. The
`pwquality` profile sets nothing beyond `retry=3`, and the package's own
`pwquality.conf` is all comments, so they apply. They only affect new
passwords; existing ones keep working until they're changed.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-pam-011 | 5.3.3.2.1 | `difok` | `2` | Enforced | `baseline::manage_pam` |  |
| hl-pam-012 | 5.3.3.2.2 | `minlen` | `14` | Enforced | `baseline::pam::pwquality_minlen` | 14 or more. |
| — | 5.3.3.2.3 | Complexity | no `minclass`; credits `0` | Monitored | — | Manual. Length and the dictionary check stand in for character classes; no credit is above 0, which CIS requires. |
| hl-pam-013 | 5.3.3.2.4 | `maxrepeat` | `3` | Enforced | `baseline::manage_pam` |  |
| hl-pam-014 | 5.3.3.2.5 | `maxsequence` | `3` | Enforced | `baseline::manage_pam` |  |
| hl-pam-015 | 5.3.3.2.6 | `dictcheck` | `1` | Enforced | `baseline::manage_pam` | The default; now explicit. |
| hl-pam-016 | 5.3.3.2.7 | `enforcing` | `1` | Enforced | `baseline::manage_pam` | The default; now explicit. |
| hl-pam-017 | 5.3.3.2.8 | `enforce_for_root` | set | Enforced | `baseline::manage_pam` | Applies when root changes a password, its own or another user's. |

#### pam_pwhistory (5.3.3.3)

`/etc/security/pwhistory.conf` is managed whole; CIS prefers it to arguments on
the module line, and the `pwhistory` profile carries only `use_authtok`. The
history is kept in `/etc/security/opasswd`, which 7.1 covers.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-pam-018 | 5.3.3.3.1 | `remember` | `24` | Enforced | `baseline::pam::pwhistory_remember` | 24 or more. |
| hl-pam-019 | 5.3.3.3.2 | `enforce_for_root` | set | Enforced | `baseline::manage_pam` |  |
| hl-pam-008 | 5.3.3.3.3 | `use_authtok` | set | Enforced | `baseline::manage_pam` | On the `pwhistory` profile line (5.3.2.4). |

#### pam_unix (5.3.3.4)

The baseline writes `/usr/share/pam-configs/unix`, libpam-runtime's profile with
`nullok` removed and everything else as shipped; CIS audits the profile itself,
so a separate profile wouldn't do. A libpam-runtime upgrade puts the stock file
back and reruns pam-auth-update, so `nullok` returns until the next Puppet run
restores the file. That only matters for an account with an empty password,
and there shouldn't be any.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-pam-020 | 5.3.3.4.1 | `nullok` | not set | Enforced | `baseline::manage_pam` | Accounts with an empty password field can't log in. |
| hl-pam-021 | 5.3.3.4.2 | `remember` | not set | Enforced | `baseline::manage_pam` | History is pam_pwhistory's (5.3.3.3). |
| hl-pam-022 | 5.3.3.4.3 | Hashing algorithm | `yescrypt` | Enforced | `baseline::manage_pam` | Debian's default. |
| hl-pam-023 | 5.3.3.4.4 | `use_authtok` | set | Enforced | `baseline::manage_pam` | On the `Password:` line, which pam-auth-update uses once pwquality is ahead of pam_unix. |

## Deviations

### hl-ssh-001: no drop-ins

CIS puts its settings in a drop-in under `/etc/ssh/sshd_config.d`, read
through the main file's `Include`. sshd takes the first value it sees for most
options, so a drop-in that sorts first wins, and cloud-init and some packages
install one (cloud-init's can set `PasswordAuthentication yes`). The baseline
writes the whole of `sshd_config` instead, with no `Include`, so nothing can
override these settings by accident. The CIS audits read `sshd -T`, so they
see the same values either way.

### hl-ssh-009: forwarding on remote development hosts

Hosts used for remote development set
`baseline::ssh::disable_forwarding: false`. Editors that run a server on the
host (VS Code Remote-SSH, for one) reach it through an SSH port forward, so
forwarding has to be on there. X11 forwarding stays off. Every other host keeps
`DisableForwarding yes`.

### hl-ssh-022: root logins on Proxmox hosts

Proxmox hosts set `baseline::ssh::permit_root_login: 'yes'`. A Proxmox cluster
logs in to its own nodes as root over SSH (migration, replication, the web
console's shell), so it can't be turned off there. Everywhere else root can't
log in over SSH.
