# @summary Default shell environment for users: idle timeout and umask.
#
# Control IDs and CIS numbers are listed in docs/controls/.
#
# Both apply to login shells. Services started by systemd keep their own
# umask.
#
# @param tmout
#   Seconds an idle shell waits before it exits (CIS 5.4.3.2 allows 1 to 900).
#
# @api private
class baseline::environment (
  Integer[1, 900] $tmout = 900,
) {
  assert_private()

  # hl-env-001, CIS 5.4.3.2. Set once, in one file: setting a readonly TMOUT
  # again later in the same shell is an error at every login. Plain POSIX
  # rather than CIS's `typeset -xr`, which dash doesn't have and login shells
  # running as sh read profile.d too.
  file { '/etc/profile.d/50-tmout.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("SH"),
      # Managed by Puppet (baseline::environment). Local changes will be overwritten.
      # Log out idle shells.
      TMOUT=${tmout}
      readonly TMOUT
      export TMOUT
      | SH
  }

  # hl-env-001, CIS 5.4.3.2. Any other TMOUT lines in the files CIS checks, as
  # its remediation says. /etc/profile reads profile.d first, so one there would
  # trip over the readonly.
  ['/etc/profile', '/etc/bash.bashrc'].each |$path| {
    file_line { "${path} TMOUT":
      ensure            => absent,
      path              => $path,
      line              => 'TMOUT',
      match             => '^\s*(export\s+|readonly\s+|typeset\s+\S+\s+)?TMOUT\b',
      match_for_absence => true,
      multiple          => true,
    }
  }

  # hl-env-002, CIS 5.4.3.3. Read by login shells after anything earlier in
  # profile.d, so it wins over a package's own umask.
  file { '/etc/profile.d/60-default_umask.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(SH),
      # Managed by Puppet (baseline::environment). Local changes will be overwritten.
      umask 027
      | SH
  }

  # hl-env-003, CIS 5.4.3.3. The default for pam_umask and new home
  # directories.
  file_line { 'login.defs UMASK':
    path  => '/etc/login.defs',
    line  => 'UMASK 027',
    match => '^\s*#?\s*UMASK\s',
  }

  # hl-env-004, CIS 5.4.3.3. Comments out any umask the CIS audit flags (less
  # restrictive than 027) in the files it reads, using the audit's pattern. That
  # pattern also flags four-digit masks such as 0077; write 077 instead.
  $weak_umask = '^\h*umask\h+(?!0?[02367]7\b)'
  $profiles = '/etc/profile /etc/profile.d/*.sh'

  exec { 'comment out weak umasks':
    command  => "grep -PlsZi '${weak_umask}' ${profiles} | xargs -0 -r perl -i -pe 's/^(?=${weak_umask})/# /i'",
    onlyif   => "grep -Pqsi '${weak_umask}' ${profiles}",
    path     => ['/usr/bin', '/bin'],
    provider => shell,
    require  => File['/etc/profile.d/60-default_umask.sh'],
  }
}
