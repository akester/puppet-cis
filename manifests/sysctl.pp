# @summary Kernel parameters, written to a baseline-owned sysctl drop-in.
#
# Each setting is persisted to `$target` and applied to the running kernel.
# Control IDs and CIS numbers are listed in docs/controls/.
#
# @param target
#   Drop-in file the settings are written to. Nothing else should manage it.
#
# @param ptrace_scope
#   Yama ptrace restriction (hl-sysctl-003). 2 limits ptrace to processes with
#   CAP_SYS_PTRACE; 1 also lets a process trace its own descendants. 3 is
#   not offered: it can't be undone without a reboot.
#
# @api private
class baseline::sysctl (
  Stdlib::Absolutepath $target       = '/etc/sysctl.d/60-baseline.conf',
  Integer[1, 2]        $ptrace_scope = 2,
) {
  assert_private()

  $settings = {
    'fs.protected_hardlinks'    => '1', # hl-sysctl-001, CIS 1.5.1
    'fs.protected_symlinks'     => '1', # hl-sysctl-002, CIS 1.5.2
    'kernel.yama.ptrace_scope'  => String($ptrace_scope), # hl-sysctl-003, CIS 1.5.3
    'fs.suid_dumpable'          => '0', # hl-sysctl-004, CIS 1.5.4
    'kernel.dmesg_restrict'     => '1', # hl-sysctl-005, CIS 1.5.5
    'kernel.kptr_restrict'      => '1', # hl-sysctl-006, CIS 1.5.8
    'kernel.randomize_va_space' => '2', # hl-sysctl-007, CIS 1.5.9
  }

  $settings.each |String $key, String $value| {
    sysctl { $key:
      value  => $value,
      target => $target,
    }
  }
}
