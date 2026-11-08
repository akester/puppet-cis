# @summary Login warning banners and an empty message of the day.
#
# `/etc/issue` (local console) and `/etc/issue.net` (remote logins) get the
# warning text; `/etc/motd` is emptied. Control IDs and CIS numbers are listed
# in docs/controls/.
#
# pam_motd (sshd, login) also shows /run/motd.dynamic, which the
# /etc/update-motd.d scripts rebuild at each login. base-files' 10-uname
# puts the kernel version there, so it's removed; dpkg doesn't restore a
# deleted conffile on upgrade.
#
# @param banner
#   Warning text for `/etc/issue` and `/etc/issue.net`. Must not contain
#   getty escapes (`\m`, `\r`, `\s`, `\v`) or the OS name (CIS 1.6.2, 1.6.3).
#
# @api private
class baseline::banners (
  String $banner = @(BANNER),


    UNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED

    You must have explicit, authorized permission to access or configure this
    device. Unauthorized attempts and actions to access or use this system may
    result in civil and/or criminal penalties. All activities performed on this
    device are logged and monitored.


    | BANNER
) {
  assert_private()

  if $banner =~ /\\[mrsv]/ {
    fail('baseline::banners::banner must not contain getty escapes (\m, \r, \s, \v)')
  }

  $files = {
    '/etc/motd'      => '',      # hl-banner-001, 004; CIS 1.6.1, 1.6.6
    '/etc/issue'     => $banner, # hl-banner-002, 005; CIS 1.6.2, 1.6.7
    '/etc/issue.net' => $banner, # hl-banner-003, 006; CIS 1.6.3, 1.6.8
  }

  $files.each |$path, $content| {
    file { $path:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $content,
    }
  }

  # hl-banner-007, CIS 1.6.4
  file { '/etc/update-motd.d/10-uname':
    ensure => absent,
  }

  # hl-banner-008, CIS 1.6.9: the motd= file Debian's sshd and login PAM
  # configs name. pam_motd rewrites it at each login; no `ensure`, so Puppet
  # only fixes ownership and mode when it exists.
  file { '/run/motd.dynamic':
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  # Ubuntu's update-notifier refreshes the dynamic motd. Debian doesn't ship
  # it, so the units are only masked where they exist. Masked rather than
  # disabled, so neither pam_motd nor the timer can start the service.
  if $facts['os']['name'] == 'Ubuntu' {
    service { [
        'update-notifier-motd.service', # hl-banner-009, CIS 1.6.11
        'update-notifier-motd.timer',   # hl-banner-010, CIS 1.6.12
      ]:
        ensure => stopped,
        enable => mask,
    }
  }
}
