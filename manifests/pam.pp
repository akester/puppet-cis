# @summary PAM packages, profiles and module options.
#
# Control IDs and CIS numbers are listed in docs/controls/.
#
# /etc/pam.d/common-* are left to pam-auth-update, which builds them from the
# profiles in /usr/share/pam-configs. Editing them directly would make it treat
# them as locally modified and stop updating them.
#
# @param faillock_deny
#   Failed attempts before an account is locked (CIS 5.3.3.1.1 allows 1 to 5).
#
# @param faillock_unlock_time
#   Seconds until a locked account unlocks: 0 (never) or at least 900
#   (CIS 5.3.3.1.2).
#
# @param pwquality_minlen
#   Minimum password length (CIS 5.3.3.2.2 asks for at least 14).
#
# @param pwhistory_remember
#   Previous passwords a user can't reuse (CIS 5.3.3.3.1 asks for at least 24).
#
# @api private
class baseline::pam (
  Integer[1, 5]                                $faillock_deny        = 5,
  Variant[Integer[0, 0], Integer[900, 604800]] $faillock_unlock_time = 900,
  Integer[14]                                  $pwquality_minlen     = 14,
  Integer[24]                                  $pwhistory_remember   = 24,
) {
  assert_private()

  # Upgrades come from unattended-upgrades (CIS 1.2.2), not from Puppet.
  $packages = [
    'libpam-runtime',   # hl-pam-001, CIS 5.3.1.1
    'libpam-modules',   # hl-pam-002, CIS 5.3.1.2
    'libpam-pwquality', # hl-pam-003, CIS 5.3.1.3
    'cracklib-runtime', # hl-pam-004, CIS 5.3.1.4
  ]

  package { $packages:
    ensure => installed,
  }

  # Profiles for pam-auth-update, as CIS gives them. libpam-pwquality ships the
  # pwquality profile (hl-pam-007) and libpam-runtime the unix one
  # (hl-pam-005). Equal priorities sort in reverse name order, so pwquality
  # runs before pwhistory and pwhistory's use_authtok gets the password
  # pwquality checked. Module options go in their own config files (5.3.3).
  $profiles = {
    # hl-pam-006, CIS 5.3.2.2
    'faillock'        => @(PROFILE),
      Name: Enable pam_faillock to deny access
      Default: yes
      Priority: 0
      Auth-Type: Primary
      Auth:
        [default=die]    pam_faillock.so authfail
      | PROFILE
    # hl-pam-006, CIS 5.3.2.2
    'faillock_notify' => @(PROFILE),
      Name: Notify of failed login attempts and reset count upon success
      Default: yes
      Priority: 1024
      Auth-Type: Primary
      Auth:
        requisite        pam_faillock.so preauth
      Account-Type: Primary
      Account:
        required         pam_faillock.so
      | PROFILE
    # hl-pam-008, CIS 5.3.2.4
    'pwhistory'       => @(PROFILE),
      Name: pwhistory password history checking
      Default: yes
      Priority: 1024
      Password-Type: Primary
      Password:
        requisite        pam_pwhistory.so use_authtok
      | PROFILE
  }

  # hl-pam-020..023, CIS 5.3.3.4.1-5.3.3.4.4. libpam-runtime's unix profile
  # without nullok, so an account with an empty password can't log in. The
  # rest is as shipped: no remember, yescrypt, and use_authtok on the Password
  # lines used once pwquality is ahead of pam_unix. A libpam-runtime upgrade
  # puts the stock file back; the next run restores this one.
  $unix = @(PROFILE)
    Name: Unix authentication
    Default: yes
    Priority: 256
    Auth-Type: Primary
    Auth:
      [success=end default=ignore]    pam_unix.so try_first_pass
    Auth-Initial:
      [success=end default=ignore]    pam_unix.so
    Account-Type: Primary
    Account:
      [success=end new_authtok_reqd=done default=ignore]    pam_unix.so
    Account-Initial:
      [success=end new_authtok_reqd=done default=ignore]    pam_unix.so
    Session-Type: Additional
    Session:
      required    pam_unix.so
    Session-Initial:
      required    pam_unix.so
    Password-Type: Primary
    Password:
      [success=end default=ignore]    pam_unix.so obscure use_authtok try_first_pass yescrypt
    Password-Initial:
      [success=end default=ignore]    pam_unix.so obscure yescrypt
    | PROFILE

  ($profiles + { 'unix' => $unix }).each |$name, $content| {
    file { "/usr/share/pam-configs/${name}":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $content,
      require => Package['libpam-runtime'],
      notify  => Exec['pam-auth-update'],
    }
  }

  # hl-pam-009, CIS 5.3.3.1.1; hl-pam-010, CIS 5.3.3.1.2. The profiles pass no
  # arguments, so these apply. Root stays exempt: 5.3.3.1.3 is Level 2.
  file { '/etc/security/faillock.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("CONF"),
      # Managed by Puppet (baseline::pam). Local changes will be overwritten.
      # Unlock an account early with: faillock --user <name> --reset
      deny = ${faillock_deny}
      unlock_time = ${faillock_unlock_time}
      | CONF
    require => Package['libpam-modules'],
  }

  # hl-pam-011..017, CIS 5.3.3.2.1-5.3.3.2.8. Nothing is set on the
  # pam_pwquality line, and the package's pwquality.conf is all comments, so
  # this file's values apply. Complexity (5.3.3.2.3) is left to length and the
  # dictionary check: no minclass, and the credits stay at 0.
  file { '/etc/security/pwquality.conf.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['libpam-pwquality'],
  }

  file { '/etc/security/pwquality.conf.d/50-baseline.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("CONF"),
      # Managed by Puppet (baseline::pam). Local changes will be overwritten.
      difok = 2
      minlen = ${pwquality_minlen}
      maxrepeat = 3
      maxsequence = 3
      dictcheck = 1
      enforcing = 1
      enforce_for_root
      | CONF
  }

  # hl-pam-018, CIS 5.3.3.3.1; hl-pam-019, CIS 5.3.3.3.2. The pwhistory profile
  # only sets use_authtok (5.3.3.3.3), so these apply.
  file { '/etc/security/pwhistory.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("CONF"),
      # Managed by Puppet (baseline::pam). Local changes will be overwritten.
      remember = ${pwhistory_remember}
      enforce_for_root
      | CONF
    require => Package['libpam-modules'],
  }

  # hl-pam-005..008, CIS 5.3.2.1-5.3.2.4. Rewrites /etc/pam.d/common-* when a
  # profile or package changes. --enable implies --package: no prompts, and
  # local changes to common-* are kept rather than forced.
  exec { 'pam-auth-update':
    command     => '/usr/sbin/pam-auth-update --enable unix faillock faillock_notify pwquality pwhistory',
    refreshonly => true,
    subscribe   => Package[$packages],
  }
}
