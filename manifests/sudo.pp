# @summary sudo and its main config, with su limited to root.
#
# Control IDs and CIS numbers are listed in docs/controls/.
#
# The whole of /etc/sudoers is managed. Site grants go in /etc/sudoers.d,
# which it still includes; the Defaults CIS checks are all in the main file.
#
# @param timestamp_timeout
#   Minutes a sudo authentication stays valid (CIS 5.2.6 allows up to 15).
#
# @api private
class baseline::sudo (
  Integer[0, 15] $timestamp_timeout = 15,
) {
  assert_private()

  # Ubuntu 25.10 and later ship sudo-rs as sudo. It has no logfile setting and
  # logs to syslog (auth.log) only.
  $sudo_rs = $facts['os']['name'] == 'Ubuntu' and versioncmp($facts['os']['release']['full'], '25.10') >= 0

  $sudoers_params = {
    'timestamp_timeout' => $timestamp_timeout,
    'logfile'           => !$sudo_rs,
  }

  # hl-sudo-001, CIS 5.2.1
  package { 'sudo':
    ensure => installed,
  }

  # hl-sudo-002, CIS 5.2.2; hl-sudo-003, CIS 5.2.3; hl-sudo-004, CIS 5.2.5;
  # hl-sudo-005, CIS 5.2.6
  file { '/etc/sudoers':
    ensure       => file,
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => epp('baseline/sudo/sudoers.epp', $sudoers_params),
    validate_cmd => '/usr/sbin/visudo -c -f %',
    require      => Package['sudo'],
  }

  # hl-sudo-003, CIS 5.2.3
  file { '/etc/logrotate.d/sudo':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(LOGROTATE),
      /var/log/sudo.log {
          daily
          rotate 5
          compress
          delaycompress
          missingok
          notifempty
          create 600 root root
      }
      | LOGROTATE
  }

  # hl-sudo-006, CIS 5.2.7. sugroup stays empty, so only root (through
  # pam_rootok, earlier in the file) can su.
  group { 'sugroup':
    ensure => present,
    system => true,
  }

  file_line { 'su pam_wheel':
    path    => '/etc/pam.d/su',
    line    => 'auth       required   pam_wheel.so use_uid group=sugroup',
    match   => '^\s*auth\s+\S+\s+pam_wheel\.so',
    after   => '^auth\s+sufficient\s+pam_rootok\.so',
    require => Group['sugroup'],
  }
}
