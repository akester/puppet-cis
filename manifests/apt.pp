# @summary apt key directory permissions and repository security settings.
#
# Only the key directories are managed, not their contents. Sources and keys
# are site-specific and live in the control repo. Control IDs and CIS numbers
# are listed in docs/controls/.
#
# @param conf
#   apt.conf.d drop-in for the repository settings. `99-` so it's read last
#   and overrides anything earlier. Nothing else should manage it.
#
# @api private
class baseline::apt (
  Stdlib::Absolutepath $conf = '/etc/apt/apt.conf.d/99-baseline',
) {
  assert_private()

  $directories = [
    '/etc/apt/trusted.gpg.d', # hl-apt-001, CIS 1.2.1.4
    '/usr/share/keyrings',    # hl-apt-002, CIS 1.2.1.7
  ]

  file { $directories:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Same as the apt defaults; set explicitly so nothing earlier can override them.
  $settings = {
    'Acquire::AllowInsecureRepositories'            => '0',    # hl-apt-003, CIS 1.2.1.12
    'Acquire::AllowWeakRepositories'                => '0',    # hl-apt-004, CIS 1.2.1.13
    'Acquire::AllowDowngradeToInsecureRepositories' => '0',    # hl-apt-005, CIS 1.2.1.14
    'Acquire::Check-Date'                           => 'true', # hl-apt-006, CIS 1.2.1.15
  }

  $lines = $settings.map |$key, $value| { "${key} \"${value}\";" }

  file { $conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "// Managed by Puppet (baseline::apt). Local changes will be overwritten.\n${lines.join("\n")}\n",
  }
}
