# @summary AppArmor userspace packages.
#
# AppArmor is enabled by default on Debian 13; this only makes sure the tools
# are installed. The 1.3.1.4 sysctl is in baseline::sysctl. Control IDs and
# CIS numbers are listed in docs/controls/.
#
# @api private
class baseline::apparmor {
  assert_private()

  $packages = [
    'apparmor',       # hl-apparmor-001, CIS 1.3.1.1
    'apparmor-utils', # hl-apparmor-002, CIS 1.3.1.1
  ]

  package { $packages:
    ensure => installed,
  }
}
