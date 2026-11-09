# @summary The OpenSSH server and its config.
#
# The whole of /etc/ssh/sshd_config is managed, with no Include, so a drop-in
# (cloud-init's, for one) can't override it. Control IDs and CIS numbers are
# listed in docs/controls/.
#
# @param ports
#   Ports sshd listens on.
#
# @param allow_groups
#   Groups allowed to log in (AllowGroups).
#
# @param permit_root_login
#   `no` meets CIS 5.1.22. Proxmox hosts set `yes`: the cluster logs in to its
#   own nodes as root.
#
# @param password_authentication
#   Whether to allow password logins. Not a CIS rule.
#
# @param disable_forwarding
#   Turns off TCP, agent and socket forwarding (CIS 5.1.9). X11 forwarding is
#   off either way.
#
# @api private
class baseline::ssh (
  Array[Stdlib::Port]                    $ports                   = [22],
  Array[String[1]]                       $allow_groups            = ['sudo', 'ssh'],
  Enum['no', 'prohibit-password', 'yes'] $permit_root_login       = 'no',
  Boolean                                $password_authentication = true,
  Boolean                                $disable_forwarding      = true,
) {
  assert_private()

  # hl-ssh-014, CIS 5.1.14. mlkem768x25519-sha256 arrived in OpenSSH 9.9,
  # along with the sntrup761x25519-sha512 name; sshd -t rejects either on an
  # older release.
  $version = $facts['baseline_openssh_version']
  $post_quantum = ($version =~ NotUndef and versioncmp($version, '9.9') >= 0) ? {
    true  => ['mlkem768x25519-sha256', 'sntrup761x25519-sha512', 'sntrup761x25519-sha512@openssh.com'],
    false => ['sntrup761x25519-sha512@openssh.com'],
  }
  $kex_algorithms = $post_quantum + ['curve25519-sha256@libssh.org', 'diffie-hellman-group-exchange-sha256']

  $sshd_params = {
    'ports'                   => $ports,
    'allow_groups'            => $allow_groups,
    'permit_root_login'       => $permit_root_login,
    'password_authentication' => $password_authentication,
    'disable_forwarding'      => $disable_forwarding,
    'kex_algorithms'          => $kex_algorithms,
  }

  package { 'openssh-server':
    ensure => installed,
  }

  # hl-ssh-001, CIS 5.1.1. Every setting from 5.1.5 to 5.1.24 is in this file.
  file { '/etc/ssh/sshd_config':
    ensure       => file,
    owner        => 'root',
    group        => 'root',
    mode         => '0600',
    content      => epp('baseline/ssh/sshd_config.epp', $sshd_params),
    validate_cmd => '/usr/sbin/sshd -t -f %',
    require      => Package['openssh-server'],
    notify       => Service['ssh'],
  }

  # hl-ssh-002, CIS 5.1.2 (and 5.1.1 for the files in it). Puppet adds the
  # search bit for directories, so the directory gets 0700. Nothing in it is
  # read, since sshd_config has no Include.
  file { '/etc/ssh/sshd_config.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    recurse => true,
    require => Package['openssh-server'],
  }

  # hl-ssh-003, CIS 5.1.3; hl-ssh-004, CIS 5.1.4. The HostKey files in
  # sshd_config. No `ensure`: sshd's package generates them.
  ['ed25519', 'rsa'].each |$type| {
    file { "/etc/ssh/ssh_host_${type}_key":
      owner => 'root',
      group => 'root',
      mode  => '0600',
    }

    file { "/etc/ssh/ssh_host_${type}_key.pub":
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }
  }

  service { 'ssh':
    ensure => running,
    enable => true,
  }
}
