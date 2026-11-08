# @summary Remove services and clients CIS chapter 2 says not to run.
#
# Services most hosts don't need are purged or masked here; a host that runs
# one on purpose lists it in `allow`. Control IDs and CIS numbers are listed
# in docs/controls/.
#
# Purging a package stops its units, but apt also removes anything that
# depends on it. Where something the fleet needs depends on the package, its
# units are masked instead and the package stays (the benchmark's own
# fallback). Masking works whether or not the unit is installed.
#
# @param allow
#   Services (keys of the lists below) to leave alone on this host, for
#   example `['autofs']` on hosts with network mounts. Combined with
#   `baseline::services_allow`.
#
# @api private
class baseline::services (
  Array[String[1]] $allow = [],
) {
  assert_private()

  # Service => packages to purge.
  $purge = {
    'autofs'        => ['autofs'],              # hl-service-001, CIS 2.1.1
    'avahi'         => ['avahi-daemon'],        # hl-service-002, CIS 2.1.2
    # hl-service-003, CIS 2.1.3. The benchmark checks for kea; isc-dhcp-server
    # is the same service and is removed too.
    'dhcp'          => [
      'kea-dhcp4-server',
      'kea-dhcp6-server',
      'kea-dhcp-ddns-server',
      'isc-dhcp-server',
    ],
    'dns'           => ['bind9'],               # hl-service-004, CIS 2.1.4
    'dnsmasq'       => ['dnsmasq'],             # hl-service-005, CIS 2.1.5
    # hl-service-006, CIS 2.1.6. The benchmark checks vsftpd and asks for any
    # other FTP server to be audited too.
    'ftp'           => [
      'vsftpd',
      'proftpd-core',
      'pure-ftpd',
    ],
    'ldap'          => ['slapd'],               # hl-service-007, CIS 2.1.7
    # hl-service-008, CIS 2.1.8. The benchmark checks dovecot; Cyrus is the
    # other IMAP/POP3 server in Debian and is removed too.
    'mail'          => [
      'dovecot-imapd',
      'dovecot-pop3d',
      'cyrus-imapd',
      'cyrus-pop3d',
    ],
    'nfs'           => ['nfs-kernel-server'],   # hl-service-009, CIS 2.1.9
    'nis'           => ['ypserv'],              # hl-service-010, CIS 2.1.10
    'print'         => ['cups'],                # hl-service-011, CIS 2.1.11
    'samba'         => ['samba'],               # hl-service-014, CIS 2.1.14
    'snmp'          => ['snmpd'],               # hl-service-015, CIS 2.1.15
    # hl-service-016, CIS 2.1.16. The benchmark checks telnetd and
    # telnetd-ssl; inetutils-telnetd is the other telnet server in Debian.
    'telnet'        => [
      'telnetd',
      'telnetd-ssl',
      'inetutils-telnetd',
    ],
    # hl-service-017, CIS 2.1.17. The benchmark checks tftpd-hpa; atftpd is
    # the other TFTP server in Debian.
    'tftp'          => [
      'tftpd-hpa',
      'atftpd',
    ],
    'proxy'         => ['squid'],               # hl-service-018, CIS 2.1.18
    'apache'        => ['apache2'],             # hl-service-019, CIS 2.1.19
    'nginx'         => ['nginx'],               # hl-service-020, CIS 2.1.19
    'xinetd'        => ['xinetd'],              # hl-service-021, CIS 2.1.20
    # Clients (CIS 2.2). Keys end in -client where a server key has the same
    # protocol name.
    'nis-client'    => ['nis'],                 # hl-client-001, CIS 2.2.1
    'rsh-client'    => ['rsh-client'],          # hl-client-002, CIS 2.2.2
    # hl-client-003, CIS 2.2.3. The benchmark checks talk; inetutils-talk is
    # the other talk client in Debian.
    'talk'          => [
      'talk',
      'inetutils-talk',
    ],
    # hl-client-004, CIS 2.2.4. inetutils-telnet is installed by default.
    'telnet-client' => [
      'telnet',
      'inetutils-telnet',
      'telnet-ssl',
    ],
    'ldap-client'   => ['ldap-utils'],          # hl-client-005, CIS 2.2.5
    # hl-client-006, CIS 2.2.6. atftp is a TFTP client, but the benchmark
    # lists it here.
    'ftp-client'    => [
      'ftp',
      'tnftp',
      'atftp',
      'inetutils-ftp',
      'ftp-ssl',
    ],
  }

  # Service => units to stop and mask.
  $mask = {
    # hl-service-012, CIS 2.1.12. nfs-common depends on rpcbind, and Proxmox
    # depends on nfs-common.
    'rpcbind' => ['rpcbind.service', 'rpcbind.socket'],
    # hl-service-013, CIS 2.1.13. The rsync client is the same package, and
    # pve-manager depends on it.
    'rsync'   => ['rsync.service'],
  }

  $allowed = ($allow + $baseline::services_allow).unique

  $unknown = $allowed - $purge.keys - $mask.keys
  unless $unknown.empty {
    fail("baseline::services::allow has services that aren't in the list: ${unknown.join(', ')}")
  }

  $absent = $purge.filter |$name, $_| { !($name in $allowed) }.values.flatten
  $masked = $mask.filter |$name, $_| { !($name in $allowed) }.values.flatten

  package { $absent:
    ensure => purged,
  }

  service { $masked:
    ensure   => stopped,
    enable   => mask,
    provider => systemd,
  }
}
