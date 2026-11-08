# @summary Limit who can schedule jobs with at.
#
# Control IDs and CIS numbers are listed in docs/controls/.
#
# at isn't installed by the baseline. `/etc/at.allow` is written either way,
# so it's already in place if at is installed later.
#
# @param allow_users
#   Users listed in `/etc/at.allow`. Only root by default; add a user in Hiera
#   on a host where they need `at`.
#
# @api private
class baseline::at (
  Array[String[1]] $allow_users = ['root'],
) {
  assert_private()

  # hl-at-001, CIS 2.4.2.1. Group daemon so the setuid-daemon at binary can
  # read it.
  file { '/etc/at.allow':
    ensure  => file,
    owner   => 'root',
    group   => 'daemon',
    mode    => '0640',
    content => "${allow_users.join("\n")}\n",
  }

  # at.allow takes precedence, so at.deny isn't read. Only fix its access if
  # it's there.
  file { '/etc/at.deny':
    owner => 'root',
    group => 'daemon',
    mode  => '0640',
  }
}
