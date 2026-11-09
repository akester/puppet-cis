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
- [ ] **Mounts:** `harden::rules::devs` has to go from `harden::harden` in the
      same change, or the `/tmp`, `/var/tmp` and `/dev/shm` mounts are declared
      twice. `harden::harden`'s `tmpfs_size` parameter goes with it; set
      `baseline::mounts::tmp_size` in Hiera instead if a host needs another size.
- [ ] **Banners:** drop `include harden::rules::banners` from `harden::harden`
      in the same change, or `/etc/issue`, `/etc/issue.net` and `/etc/motd`
      are declared twice. Hosts that still include `harden::rules::banners`
      directly set `baseline::manage_banners: false` until they're moved.
      The first run rewrites both issue files once: the old heredoc left six
      stray spaces on the first line.
- [ ] **Services:** hosts that run a service the baseline removes need it
      allowed *before* the switch, or it's purged or masked on the first run:

      | Host | Allow |
      |---|---|
      | Includes `autofs::base` (NFSv3 client) | `autofs`, `rpcbind` |
      | Proxmox hosts with NFS storage | `rpcbind` |
      | NFS servers | `nfs`, `rpcbind` |
      | DHCP server | `dhcp` |
      | Domain controller | `dns`, `samba`, `ldap-client`, `nginx` (Zentyal web admin) |
      | Network-boots the Pis | `tftp` |
      | Includes `nginx::base` | `nginx` |
      | Includes `ups::server` (nut-cgi) | `apache` |

      Where a control-repo class declares the package too (autofs, DHCP,
      `puppet/nfs`, tftpd-hpa, nginx, apache2), a missing allow fails the
      catalog on a duplicate declaration. Where the package was installed
      outside Puppet (bind9, samba and ldap-utils on the DC), nothing fails: it's just
      purged. `harden::harden` passes these in `baseline`'s `services_allow`,
      worked out from the node's `classes`; anything else goes in
      `baseline::services::allow` in the node's Hiera.
- [ ] **cron:** only root is in `/etc/cron.allow`. Move any job that runs as
      another user (Puppet `cron` resources with a `user`) to a systemd timer
      (`cronjobs::job`) first.
- [ ] **avahi:** the baseline purges `avahi-daemon`. Any container that
      bind-mounts its socket gets an empty directory there instead.
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
| `harden::harden::tmpfs_size` | `baseline::mounts::tmp_size` | Not from os_hardening. Never overridden today. |
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
