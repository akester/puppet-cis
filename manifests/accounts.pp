# @summary Password ageing, root's access and umask, and login shells.
#
# Control IDs and CIS numbers are listed in docs/controls/.
#
# login.defs and useradd's defaults only apply to accounts created afterwards,
# so accounts that already have a password are brought into line with chage.
# Only accounts with a password hash are touched: a locked ('!') or key-only
# ('*') account has no password to expire.
#
# @param pass_max_days
#   Days before a password must be changed (CIS 5.4.1.1 allows 1 to 365).
#
# @param pass_warn_age
#   Days of warning before a password expires (CIS 5.4.1.3 asks for at least 7).
#
# @param inactive
#   Days after expiry before a new account is locked (CIS 5.4.1.5 allows up to
#   45). Existing accounts keep theirs; see docs/controls/5-access-control.md.
#
# @param shell_allow
#   System accounts that keep their login shell (CIS 5.4.2.7), for a service
#   that runs commands through it, such as GitLab's git user over SSH.
#
# @api private
class baseline::accounts (
  Integer[1, 365]  $pass_max_days = 365,
  Integer[7]       $pass_warn_age = 7,
  Integer[0, 45]   $inactive      = 45,
  Array[String[1]] $shell_allow   = [],
) {
  assert_private()

  # hl-acct-001, CIS 5.4.1.1; hl-acct-003, CIS 5.4.1.3; hl-acct-005, CIS 5.4.1.4.
  # YESCRYPT matches pam_unix (hl-pam-022), which hashes user passwords; this
  # setting only covers group passwords.
  $login_defs = {
    'PASS_MAX_DAYS'  => $pass_max_days,
    'PASS_WARN_AGE'  => $pass_warn_age,
    'ENCRYPT_METHOD' => 'YESCRYPT',
  }

  $login_defs.each |$key, $value| {
    file_line { "login.defs ${key}":
      path  => '/etc/login.defs',
      line  => "${key} ${value}",
      match => "^\\s*#?\\s*${key}\\s",
    }
  }

  # hl-acct-006, CIS 5.4.1.5. What useradd -D -f writes.
  file_line { 'useradd INACTIVE':
    path  => '/etc/default/useradd',
    line  => "INACTIVE=${inactive}",
    match => '^\s*#?\s*INACTIVE=',
  }

  # hl-acct-002, CIS 5.4.1.1; hl-acct-004, CIS 5.4.1.3. The CIS remediation:
  # accounts with a password hash whose field is out of range. An empty field
  # compares as less than 1, so it's caught too. A password last changed more
  # than pass_max_days ago expires at once and must be changed at next login.
  $chage = {
    'maxdays'  => ["(\$5 > ${pass_max_days} || \$5 < 1)", $pass_max_days],
    'warndays' => ["\$6 < ${pass_warn_age}", $pass_warn_age],
  }

  $chage.each |$option, $settings| {
    $users = "/usr/bin/awk -F: '\$2 ~ /^\\\$.+\\\$/ && ${settings[0]} { print \$1 }' /etc/shadow"

    exec { "chage --${option}":
      command  => "${users} | /usr/bin/xargs -r -n1 /usr/bin/chage --${option} ${settings[1]}",
      onlyif   => "${users} | /usr/bin/grep -q .",
      provider => shell,
    }
  }

  # hl-acct-008, CIS 5.4.2.4. Only an empty password field is changed; a set
  # password (Proxmox's root@pam) or a locked one is left alone.
  exec { 'lock root without a password':
    command => '/usr/sbin/usermod -L root',
    onlyif  => '/usr/bin/awk -F: \'$1 == "root" && $2 == "" { found = 1 } END { exit !found }\' /etc/shadow',
  }

  # hl-acct-009, CIS 5.4.2.6. Root gets the system default umask (5.4.3.3).
  ['/root/.profile', '/root/.bashrc'].each |$rc| {
    file_line { "${rc} umask":
      ensure            => absent,
      path              => $rc,
      line              => 'umask 027',
      match             => '^\s*umask\s',
      match_for_absence => true,
      multiple          => true,
    }
  }

  # hl-acct-010, CIS 5.4.2.7. System accounts (below UID_MIN, and nobody) with
  # a valid shell, except those CIS exempts and shell_allow. Valid shells are
  # those in /etc/shells other than nologin, as CIS counts them.
  $exempt = (['root', 'halt', 'sync', 'shutdown', 'nfsnobody'] + $shell_allow).join('|')
  $system_with_shell = @(CMD/L)
    min=$(awk '$1 == "UID_MIN" { print $2 }' /etc/login.defs); \
    awk -F: -v min="${min:-1000}" -v exempt="$EXEMPT" \
    'NR == FNR { if ($0 ~ /^\// && $0 !~ /\/nologin$/) valid[$0]; next } \
    $1 !~ exempt && ($3 < min || $3 == 65534) && ($NF in valid) { print $1 }' \
    /etc/shells /etc/passwd
    | - CMD

  exec { 'nologin for system accounts':
    command     => "${system_with_shell} | xargs -r -n1 usermod -s /usr/sbin/nologin",
    onlyif      => "${system_with_shell} | grep -q .",
    environment => ["EXEMPT=^(${exempt})\$"],
    path        => ['/usr/sbin', '/usr/bin'],
    provider    => shell,
  }

  # hl-acct-011, CIS 5.4.2.8. Non-root accounts without a valid shell whose
  # password isn't locked ('!') or unusable ('*'), which passwd -S shows as L.
  $unlocked_without_shell = @(CMD/L)
    awk -F: 'FILENAME == "/etc/shells" { if ($0 ~ /^\// && $0 !~ /\/nologin$/) valid[$0]; next } \
    FILENAME == "/etc/passwd" { if ($1 != "root" && !($NF in valid)) noshell[$1]; next } \
    ($1 in noshell) && $2 !~ /^[!*]/ { print $1 }' \
    /etc/shells /etc/passwd /etc/shadow
    | - CMD

  exec { 'lock accounts without a shell':
    command  => "${unlocked_without_shell} | xargs -r -n1 usermod -L",
    onlyif   => "${unlocked_without_shell} | grep -q .",
    path     => ['/usr/sbin', '/usr/bin'],
    provider => shell,
    require  => Exec['nologin for system accounts'],
  }
}
