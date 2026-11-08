# 2 Services

Controls from chapter 2 of the CIS Debian Linux 13 Benchmark v1.1.0. The
section-level status is in [cis-coverage.md](../cis-coverage.md).

## Controls

### Server services (2.1)

`baseline::services` purges the services most hosts don't need, or masks
their units where something the fleet needs depends on the package
(`baseline::manage_services => false` turns it off). A host that runs one on
purpose lists it in `baseline::services::allow`, for example `['autofs']`, or
the profile that declares `baseline` passes it in `services_allow`.

| ID | CIS | Setting | Value | Status | Parameter | Notes |
|---|---|---|---|---|---|---|
| hl-service-001 | 2.1.1 | `autofs` package | purged | Enforced | `baseline::services::allow` (`autofs`) | Allowed on hosts with network mounts (`autofs::base` in the control repo). See below. |
| hl-service-002 | 2.1.2 | `avahi-daemon` package | purged | Enforced | `baseline::services::allow` (`avahi`) | Purging stops `avahi-daemon.service` and `.socket`. |
| hl-service-003 | 2.1.3 | DHCP server packages | purged | Enforced | `baseline::services::allow` (`dhcp`) | `kea-dhcp4-server`, `kea-dhcp6-server`, `kea-dhcp-ddns-server`. Also `isc-dhcp-server`, which the benchmark doesn't check. Allowed on the DHCP server. |
| hl-service-004 | 2.1.4 | `bind9` package | purged | Enforced | `baseline::services::allow` (`dns`) | Purging stops `named.service`. Allowed on the domain controller, where Samba AD serves DNS through BIND9_DLZ. |
| hl-service-005 | 2.1.5 | `dnsmasq` package | purged | Enforced | `baseline::services::allow` (`dnsmasq`) | Not used anywhere. `dnsmasq-base` (the binary alone, which other packages pull in) is left alone. Proxmox only suggests `dnsmasq`, for SDN DHCP. |
| hl-service-006 | 2.1.6 | FTP server packages | purged | Enforced | `baseline::services::allow` (`ftp`) | `vsftpd`, which the benchmark checks, plus `proftpd-core` and `pure-ftpd`, which it asks to be audited. Not used anywhere. TFTP is 2.1.17. |
| hl-service-007 | 2.1.7 | `slapd` package | purged | Enforced | `baseline::services::allow` (`ldap`) | The domain controller's directory is Samba AD's built-in LDAP, not OpenLDAP. |
| hl-service-008 | 2.1.8 | IMAP and POP3 server packages | purged | Enforced | `baseline::services::allow` (`mail`) | `dovecot-imapd` and `dovecot-pop3d`, which the benchmark checks, plus `cyrus-imapd` and `cyrus-pop3d`. Mail runs in a dedicated container, outside the baseline's scope. |
| hl-service-009 | 2.1.9 | `nfs-kernel-server` package | purged | Enforced | `baseline::services::allow` (`nfs`) | Allowed on NFS servers, which also need `nfsd` in `baseline::kmod::allow`. NFS clients (`nfs-common`) aren't affected. |
| hl-service-010 | 2.1.10 | `ypserv` package | purged | Enforced | `baseline::services::allow` (`nis`) | Not used anywhere, including the domain controller. |
| hl-service-011 | 2.1.11 | `cups` package | purged | Enforced | `baseline::services::allow` (`print`) | Not used anywhere. |
| hl-service-012 | 2.1.12 | `rpcbind.service`, `rpcbind.socket` | masked | Enforced | `baseline::services::allow` (`rpcbind`) | Masked, not purged: `nfs-common` depends on `rpcbind`, and Proxmox depends on `nfs-common`. NFSv3 clients and NFS servers need it running, so they allow it. |
| hl-service-013 | 2.1.13 | `rsync.service` | masked | Enforced | `baseline::services::allow` (`rsync`) | Masked, not purged: the rsync client is the same package, and `pve-manager` depends on it. The unit only starts if `/etc/rsyncd.conf` exists anyway. |
| hl-service-014 | 2.1.14 | `samba` package | purged | Enforced | `baseline::services::allow` (`samba`) | Client tools (`smbclient`, `cifs-utils`) aren't affected. |
| hl-service-015 | 2.1.15 | `snmpd` package | purged | Enforced | `baseline::services::allow` (`snmp`) | The SNMP agent only; client libraries and tools aren't affected. |
| hl-service-016 | 2.1.16 | Telnet server packages | purged | Enforced | `baseline::services::allow` (`telnet`) | `telnetd` and `telnetd-ssl`, which the benchmark checks, plus `inetutils-telnetd`. |
| hl-service-017 | 2.1.17 | TFTP server packages | purged | Enforced | `baseline::services::allow` (`tftp`) | `tftpd-hpa`, which the benchmark checks, plus `atftpd`. Allowed on the host that network-boots the Pis. |
| hl-service-018 | 2.1.18 | `squid` package | purged | Enforced | `baseline::services::allow` (`proxy`) | Nothing in the fleet is a forward proxy. |
| hl-service-019 | 2.1.19 | `apache2` package | purged | Enforced | `baseline::services::allow` (`apache`) | Separate key from nginx, so a host allows only the one it runs. |
| hl-service-020 | 2.1.19 | `nginx` package | purged | Enforced | `baseline::services::allow` (`nginx`) | Allowed on web and reverse-proxy hosts. |
| hl-service-021 | 2.1.20 | `xinetd` package | purged | Enforced | `baseline::services::allow` (`xinetd`) | |
| — | 2.1.21 | X window server not in use | — | Omitted | — | Level 2. No host runs a desktop anyway (see 1.7). |
| — | 2.1.22 | MTA local-only | — | Replaced | — | Control repo: the `postfix` module sets `inet_interfaces = loopback-only`. |
| — | 2.1.23 | Only approved services listening | — | Monitored | — | Manual rule: no automated check. Host firewalls (chapter 4) limit what's reachable. |

## Deviations

### hl-service-001: autofs for static network mounts

Network shares are mounted with autofs rather than fstab, so a mount recovers
by itself if the file server drops out briefly. Hosts that need one include
`autofs::base` from the control repo and set `baseline::services::allow:
['autofs']`; everywhere else the package is purged.

CIS is concerned with removable media appearing in the filesystem without an
explicit mount. Here autofs only mounts the network shares in its static maps.
The master map is the Debian default (no `-hosts` or other on-demand maps),
browsing is off, and nothing maps local block devices.

Wazuh SCA fails 2.1.1 on hosts that run autofs; that's accepted.
