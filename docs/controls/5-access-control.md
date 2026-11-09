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
| hl-ssh-009 | 5.1.9 | `DisableForwarding` | `yes` | Enforced | `baseline::ssh::disable_forwarding` | `X11Forwarding no` stays set when this is turned off. |
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

## Deviations

### hl-ssh-001: no drop-ins

CIS puts its settings in a drop-in under `/etc/ssh/sshd_config.d`, read
through the main file's `Include`. sshd takes the first value it sees for most
options, so a drop-in that sorts first wins, and cloud-init and some packages
install one (cloud-init's can set `PasswordAuthentication yes`). The baseline
writes the whole of `sshd_config` instead, with no `Include`, so nothing can
override these settings by accident. The CIS audits read `sshd -T`, so they
see the same values either way.

### hl-ssh-022: root logins on Proxmox hosts

Proxmox hosts set `baseline::ssh::permit_root_login: 'yes'`. A Proxmox cluster
logs in to its own nodes as root over SSH (migration, replication, the web
console's shell), so it can't be turned off there. Everywhere else root can't
log in over SSH.
