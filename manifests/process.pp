# @summary Process hardening outside sysctl: unwanted packages and core dumps.
#
# The 1.5 sysctls (including fs.suid_dumpable) are in baseline::sysctl.
# Control IDs and CIS numbers are listed in docs/controls/.
#
# Core dumps are off two ways: a hard `core 0` limit for login sessions
# (pam_limits), and systemd-coredump told to neither process nor keep a dump.
# The coredump drop-in is written whether or not systemd-coredump is
# installed, so it's already in place if it gets pulled in later.
#
# @param limits_conf
#   limits.d drop-in for the core size limit. Nothing else should manage it.
#
# @param coredump_conf
#   coredump.conf.d drop-in for systemd-coredump. Nothing else should manage it.
#
# @api private
class baseline::process (
  Stdlib::Absolutepath $limits_conf   = '/etc/security/limits.d/60-baseline.conf',
  Stdlib::Absolutepath $coredump_conf = '/etc/systemd/coredump.conf.d/60-baseline.conf',
) {
  assert_private()

  # Neither package is installable on Debian 13, so in practice this keeps
  # them from coming back.
  $absent = [
    'prelink', # hl-process-001, CIS 1.5.6
    'apport',  # hl-process-002, CIS 1.5.7
  ]

  package { $absent:
    ensure => purged,
  }

  # hl-process-003, CIS 1.5.10
  file { $limits_conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(LIMITS),
      # Managed by Puppet (baseline::process). Local changes will be overwritten.
      * hard core 0
      | LIMITS
  }

  # Read by systemd-coredump on each crash; nothing to reload.
  file { dirname($coredump_conf):
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # hl-process-004, CIS 1.5.11: ProcessSizeMax
  # hl-process-005, CIS 1.5.12: Storage
  file { $coredump_conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(COREDUMP),
      # Managed by Puppet (baseline::process). Local changes will be overwritten.
      [Coredump]
      ProcessSizeMax=0
      Storage=none
      | COREDUMP
  }
}
