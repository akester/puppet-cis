# Migrating a host from os_hardening

Checklist for switching a node from `os_hardening` to `baseline`. Add to it
whenever a ported feature leaves something behind that os_hardening created.

## Before the switch

- [ ] Node is in the `baseline` branch of `harden::harden` (declares `baseline`
      instead of `os_hardening`; never both).
- [ ] Rename the node's Hiera keys from `os_hardening::*` to the matching
      `baseline::*` parameters.
- [ ] **NFS servers:** set `baseline::kmod::allow: ['nfsd']` in the node's
      Hiera *before* the switch, or the NFS server won't start after the next
      reboot. Only a few hosts; check each one that exports NFS
      (`systemctl is-active nfs-server`).
- [ ] Kernel modules: set `baseline::kmod::allow` on hosts that need another
      module the baseline denies: `usb-storage` for USB
      disks, `cifs` for SMB mounts, `xfs`/`btrfs` for any such volume. Check
      the Puppet log for "not denying mounted filesystem modules" after the
      first run.
- [ ] LXC nodes: `harden::harden` passes `manage_sysctl => false` (replaces
      os_hardening's `system_environment => 'lxc'`).

### Hiera key mapping

| os_hardening | baseline | Notes |
|---|---|---|
| `enable_ipv4_forwarding` | `baseline::sysctl::ipv4_forwarding` | Per-node; about 22 nodes. |
| `enable_ipv6_forwarding` | `baseline::sysctl::ipv6_forwarding` | Not set anywhere today. |
| `enable_log_martians` | `baseline::sysctl::log_martians` | Don't carry over the `false` in `common.yaml`: the baseline now turns it off only on forwarding hosts. |
| `manage_ipv6` | `baseline::sysctl::manage_ipv6` | Baseline only manages 3.3.2; it never disables IPv6. |
| `enable_ipv6` | — | Dropped. IPv6 status is CIS 3.1.1, not ported yet. |
| `enable_rpfilter`, `rpfilter_loose` | `baseline::sysctl::rp_filter` (1 or 2) | Not set anywhere today. |
| `system_environment: lxc` | `baseline::manage_sysctl: false` | |
| `disable_filesystems` | — | Dropped; the list is fixed to CIS Level 1. Use `baseline::kmod::allow` to exempt. |

## After the first baseline run

- [ ] **sysctl:** remove the entries os_hardening wrote to `/etc/sysctl.conf`.
      Debian 13 loads that file last (via `/etc/sysctl.d/99-sysctl.conf`), so
      stale values there override the baseline drop-in at boot. Check with
      `systemd-analyze cat-config sysctl.d` and confirm with `sysctl -a` after
      a reboot. Once removed, `tcp_timestamps`, `arp_ignore`, `arp_announce`
      and the ICMP rate limits go back to kernel defaults (see "Not carried
      over" in [3-network.md](controls/3-network.md)).
- [ ] **Kernel modules:** remove os_hardening's `/etc/modprobe.d/dev-sec.conf`
      (handled in the control repo, not by the baseline).
- [ ] **PAM:** remove `/usr/share/pam-configs/tally2` (pam_tally2 no longer
      exists; see the migration brief §2).

## Verify

- [ ] Second Puppet run makes no changes.
- [ ] Key-based SSH and `sudo` still work; host survives a reboot.
