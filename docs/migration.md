# Migrating a host from os_hardening

Checklist for switching a node from `os_hardening` to `baseline`. Add to it
whenever a ported feature leaves something behind that os_hardening created.

## Before the switch

- [ ] Node is in the `baseline` branch of `harden::harden` (declares `baseline`
      instead of `os_hardening`; never both).
- [ ] Rename the node's Hiera keys from `os_hardening::*` to the matching
      `baseline::*` parameters.
- [ ] LXC nodes: `harden::harden` passes `manage_sysctl => false` (replaces
      os_hardening's `system_environment => 'lxc'`).

## After the first baseline run

- [ ] **sysctl:** remove the entries os_hardening wrote to `/etc/sysctl.conf`.
      Debian 13 loads that file last (via `/etc/sysctl.d/99-sysctl.conf`), so
      stale values there override the baseline drop-in at boot. Check with
      `systemd-analyze cat-config sysctl.d` and confirm with `sysctl -a` after
      a reboot.
- [ ] **PAM:** remove `/usr/share/pam-configs/tally2` (pam_tally2 no longer
      exists; see the migration brief §2).

## Verify

- [ ] Second Puppet run makes no changes.
- [ ] Key-based SSH and `sudo` still work; host survives a reboot.
