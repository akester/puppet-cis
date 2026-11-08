# @summary tmpfs mounts for /tmp, /var/tmp and /dev/shm, with hardened options.
#
# Each mount is written to /etc/fstab and mounted (or remounted when the
# options change). Control IDs and CIS numbers are listed in docs/controls/.
#
# `/tmp` is not mounted `noexec` (CIS 1.1.2.1.4): apt maintainer scripts and
# installers write executables there and run them.
#
# @param tmp_size
#   Size limit of the `/tmp` tmpfs, in the tmpfs `size=` syntax (e.g. `1G`,
#   `512M`, `25%`).
#
# @api private
class baseline::mounts (
  Pattern[/\A\d+[kKmMgG%]?\z/] $tmp_size = '1G',
) {
  assert_private()

  # hl-mount-001, CIS 1.1.2.1.1: tmpfs
  # hl-mount-002, CIS 1.1.2.1.2: nodev
  # hl-mount-003, CIS 1.1.2.1.3: nosuid
  mount { '/tmp':
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => "defaults,rw,nosuid,nodev,relatime,size=${tmp_size}",
  }

  # hl-mount-008, CIS 1.1.2.5.1: separate partition (tmpfs; Level 2, kept as an addition)
  # hl-mount-009, CIS 1.1.2.5.2: nodev
  # hl-mount-010, CIS 1.1.2.5.3: nosuid
  # hl-mount-011, CIS 1.1.2.5.4: noexec
  mount { '/var/tmp':
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => 'defaults,rw,nosuid,nodev,noexec,relatime',
  }

  # hl-mount-004, CIS 1.1.2.2.1: tmpfs
  # hl-mount-005, CIS 1.1.2.2.2: nodev
  # hl-mount-006, CIS 1.1.2.2.3: nosuid
  # hl-mount-007, CIS 1.1.2.2.4: noexec
  mount { '/dev/shm':
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => 'defaults,rw,nosuid,nodev,noexec,relatime',
  }
}
