# @summary Ownership and mode of the GRUB config.
#
# No `ensure`, so Puppet only fixes ownership and mode where the file exists
# and never creates one (LXC containers and other hosts without GRUB).
# update-grub rewrites the file with its own mode; the next run puts it back.
# Control IDs and CIS numbers are listed in docs/controls/.
#
# @param grub_cfg
#   Path to the generated GRUB config.
#
# @api private
class baseline::bootloader (
  Stdlib::Absolutepath $grub_cfg = '/boot/grub/grub.cfg',
) {
  assert_private()

  # hl-boot-001, CIS 1.4.2
  file { $grub_cfg:
    owner => 'root',
    group => 'root',
    mode  => '0600',
  }
}
