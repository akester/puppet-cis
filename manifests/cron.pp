# @summary cron running, with its config root-only.
#
# Control IDs and CIS numbers are listed in docs/controls/.
#
# `/etc/cron.allow` lists only root, so only root can run `crontab`. Scheduled
# jobs for other users belong in systemd timers.
#
# @api private
class baseline::cron {
  assert_private()

  package { 'cron':
    ensure => installed,
  }

  # hl-cron-001, CIS 2.4.1.1
  service { 'cron':
    ensure  => running,
    enable  => true,
    require => Package['cron'],
  }

  # hl-cron-002, CIS 2.4.1.2
  file { '/etc/crontab':
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => Package['cron'],
  }

  $dirs = [
    '/etc/cron.hourly',  # hl-cron-003, CIS 2.4.1.3
    '/etc/cron.daily',   # hl-cron-004, CIS 2.4.1.4
    '/etc/cron.weekly',  # hl-cron-005, CIS 2.4.1.5
    '/etc/cron.monthly', # hl-cron-006, CIS 2.4.1.6
    '/etc/cron.yearly',  # hl-cron-007, CIS 2.4.1.7
    '/etc/cron.d',       # hl-cron-008, CIS 2.4.1.8
  ]

  file { $dirs:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => Package['cron'],
  }

  # hl-cron-009, CIS 2.4.1.9. Group crontab so the setgid crontab binary can
  # read it; cron denies everyone if it can't.
  file { '/etc/cron.allow':
    ensure  => file,
    owner   => 'root',
    group   => 'crontab',
    mode    => '0640',
    content => "root\n",
    require => Package['cron'],
  }

  # cron.allow takes precedence, so cron.deny isn't read. Only fix its
  # access if it's there.
  file { '/etc/cron.deny':
    owner   => 'root',
    group   => 'crontab',
    mode    => '0640',
    require => Package['cron'],
  }
}
