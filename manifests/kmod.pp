# @summary Kernel modules that must not load, via a baseline-owned modprobe drop-in.
#
# Each module gets `install <name> /bin/false` (any load attempt fails) and
# `blacklist <name>` (no automatic loading by alias). Already-loaded modules
# are not unloaded; the change takes full effect at the next boot. Control IDs
# and CIS numbers are listed in docs/controls/.
#
# A filesystem module is never denied while a filesystem of that type is
# mounted (from the `mountpoints` fact): denying the root or /boot filesystem
# would make the host unbootable after the next initramfs rebuild. Puppet logs
# a warning instead; add the module to `allow` to silence it.
#
# @param allow
#   Modules from the lists below to leave loadable on this host, e.g.
#   `['usb-storage']`. Names must match the lists exactly.
#
# @param target
#   Drop-in file the rules are written to. Nothing else should manage it.
#
# @api private
class baseline::kmod (
  Array[String[1]]     $allow  = [],
  Stdlib::Absolutepath $target = '/etc/modprobe.d/60-baseline.conf',
) {
  assert_private()

  $modules = [
    'cramfs',        # hl-kmod-001, CIS 1.1.1.1
    'freevxfs',      # hl-kmod-002, CIS 1.1.1.2
    'hfs',           # hl-kmod-003, CIS 1.1.1.3
    'hfsplus',       # hl-kmod-004, CIS 1.1.1.4
    'jffs2',         # hl-kmod-005, CIS 1.1.1.5
    'firewire-core', # hl-kmod-006, CIS 1.1.1.9
    'usb-storage',   # hl-kmod-007, CIS 1.1.1.10
    'atm',           # hl-kmod-008, CIS 3.2.1
    'can',           # hl-kmod-009, CIS 3.2.2
    'dccp',          # hl-kmod-010, CIS 3.2.3
    'rds',           # hl-kmod-011, CIS 3.2.4
    'sctp',          # hl-kmod-012, CIS 3.2.5
    'tipc',          # hl-kmod-013, CIS 3.2.6
    # hl-kmod-015, CIS 3.1.2. Every Wi-Fi driver depends on cfg80211, and
    # modprobe runs a dependency's install command too, so this one entry
    # stops all of them loading whatever the kernel ships.
    'cfg80211',
    # hl-kmod-016, CIS 3.1.3: the Bluetooth core, which every Bluetooth
    # driver (btusb, hci_uart) depends on. Same approach as cfg80211.
    'bluetooth',
  ]

  # hl-kmod-014, CIS 1.1.1.11: every other filesystem module in the Debian 13
  # kernel's kernel/fs/ that the fleet doesn't use. Deliberately left loadable:
  # ext4 (also mounts ext2), jbd2, fat, vfat (EFI system partition), isofs
  # (cloud-init and install media), efivarfs, autofs4 and configfs (systemd),
  # overlay (Docker, K3s), squashfs (kept by choice), and the NFS client:
  # nfs, nfsv3, nfsv4, lockd, grace, nfs_acl, netfs. NFS servers add nfsd
  # through $allow.
  $unused_filesystems = [
    '9p', 'adfs', 'affs', 'bcachefs', 'befs', 'bfs', 'btrfs', 'cachefiles',
    'ceph', 'cifs', 'coda', 'cuse', 'dlm', 'ecryptfs', 'efs', 'erofs', 'exfat',
    'f2fs', 'gfs2', 'hpfs', 'jfs', 'kafs', 'ksmbd', 'minix', 'msdos', 'nfsd',
    'nfsv2', 'nilfs2', 'ntfs3', 'ocfs2', 'ocfs2_stack_o2cb', 'ocfs2_stack_user',
    'ocfs2_stackglue', 'omfs', 'orangefs', 'pstore_blk', 'pstore_zone', 'qnx4',
    'qnx6', 'quota_tree', 'quota_v1', 'quota_v2', 'ramoops', 'reiserfs',
    'romfs', 'sysv', 'ubifs', 'udf', 'ufs', 'vboxsf', 'xfs', 'zonefs',
  ]

  $all = $modules + $unused_filesystems

  $unknown = $allow - $all
  unless $unknown.empty {
    fail("baseline::kmod::allow has modules that aren't in the list: ${unknown.join(', ')}")
  }

  # Filesystem types whose module name differs from the type.
  $fstype_module = {
    'ext2'    => 'ext4',
    'ext3'    => 'ext4',
    'iso9660' => 'isofs',
    'nfs4'    => 'nfs',
    'smb3'    => 'cifs',
  }
  $mounted = pick($facts['mountpoints'], {}).map |$_mount, $info| {
    $type = $info['filesystem']
    pick($fstype_module[$type], $type)
  }.unique
  $in_use = ($all - $allow).filter |$module| { $module in $mounted }
  unless $in_use.empty {
    warning("baseline::kmod: not denying mounted filesystem modules: ${in_use.join(', ')}. Add them to baseline::kmod::allow.")
  }

  file { $target:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('baseline/kmod/modprobe.conf.epp', { 'modules' => $all - $allow - $in_use }),
  }
}
