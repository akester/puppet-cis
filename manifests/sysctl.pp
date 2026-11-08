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
# @param ipv4_forwarding
#   Allow IPv4 forwarding (hl-sysctl-008..010). Needed on container hosts,
#   K3s nodes and routers; Docker turns it back on at runtime regardless.
#
# @param rp_filter
#   IPv4 reverse path filtering (hl-sysctl-019, 020). 1 is strict, 2 is loose
#   (for asymmetric routing).
#
# @param log_martians
#   Log packets with impossible source addresses (hl-sysctl-023, 024).
#   Defaults to the opposite of `ipv4_forwarding`: forwarding hosts see
#   container and pod traffic that looks martian and would flood the log.
#
# @param manage_ipv6
#   Manage the IPv6 parameters (hl-sysctl-027..034). Set false only on hosts
#   booted with IPv6 disabled, where the keys don't exist.
#
# @param ipv6_forwarding
#   Allow IPv6 forwarding (hl-sysctl-027, 028).
#
# @api private
class baseline::sysctl (
  Stdlib::Absolutepath $target          = '/etc/sysctl.d/60-baseline.conf',
  Integer[1, 2]        $ptrace_scope    = 2,
  Boolean              $ipv4_forwarding = false,
  Integer[1, 2]        $rp_filter       = 1,
  Optional[Boolean]    $log_martians    = undef,
  Boolean              $manage_ipv6     = true,
  Boolean              $ipv6_forwarding = false,
) {
  assert_private()

  $forward4 = bool2str($ipv4_forwarding, '1', '0')
  $forward6 = bool2str($ipv6_forwarding, '1', '0')
  $martians = bool2str(pick($log_martians, !$ipv4_forwarding), '1', '0')

  $kernel_all = {
    'fs.protected_hardlinks'                           => '1', # hl-sysctl-001, CIS 1.5.1
    'fs.protected_symlinks'                            => '1', # hl-sysctl-002, CIS 1.5.2
    'kernel.yama.ptrace_scope'                         => String($ptrace_scope), # hl-sysctl-003, CIS 1.5.3
    'fs.suid_dumpable'                                 => '0', # hl-sysctl-004, CIS 1.5.4
    'kernel.dmesg_restrict'                            => '1', # hl-sysctl-005, CIS 1.5.5
    'kernel.kptr_restrict'                             => '1', # hl-sysctl-006, CIS 1.5.8
    'kernel.randomize_va_space'                        => '2', # hl-sysctl-007, CIS 1.5.9
    'kernel.sysrq'                                     => '0', # hl-sysctl-035, not CIS
    'kernel.apparmor_restrict_unprivileged_unconfined' => '1', # hl-sysctl-037, CIS 1.3.1.4
  }

  # Yama and AppArmor only register their sysctls while the security module is
  # active, which it isn't on every kernel (e.g. the Raspberry Pi one). Skip
  # those keys when the baseline_lsm fact says the module is off. Without the
  # fact, manage them anyway.
  $lsm = $facts['baseline_lsm']
  $lsm_keys = {
    'kernel.yama.ptrace_scope'                         => 'yama',
    'kernel.apparmor_restrict_unprivileged_unconfined' => 'apparmor',
  }
  $kernel = $kernel_all.filter |$key, $_value| {
    $lsm =~ Undef or !($key in $lsm_keys) or $lsm_keys[$key] in $lsm
  }

  $ipv4 = {
    'net.ipv4.ip_forward'                        => $forward4, # hl-sysctl-008, CIS 3.3.1.1
    'net.ipv4.conf.all.forwarding'               => $forward4, # hl-sysctl-009, CIS 3.3.1.2
    'net.ipv4.conf.default.forwarding'           => $forward4, # hl-sysctl-010, CIS 3.3.1.3
    'net.ipv4.conf.all.send_redirects'           => '0', # hl-sysctl-011, CIS 3.3.1.4
    'net.ipv4.conf.default.send_redirects'       => '0', # hl-sysctl-012, CIS 3.3.1.5
    'net.ipv4.icmp_ignore_bogus_error_responses' => '1', # hl-sysctl-013, CIS 3.3.1.6
    'net.ipv4.icmp_echo_ignore_broadcasts'       => '1', # hl-sysctl-014, CIS 3.3.1.7
    'net.ipv4.conf.all.accept_redirects'         => '0', # hl-sysctl-015, CIS 3.3.1.8
    'net.ipv4.conf.default.accept_redirects'     => '0', # hl-sysctl-016, CIS 3.3.1.9
    'net.ipv4.conf.all.secure_redirects'         => '0', # hl-sysctl-017, CIS 3.3.1.10
    'net.ipv4.conf.default.secure_redirects'     => '0', # hl-sysctl-018, CIS 3.3.1.11
    'net.ipv4.conf.all.rp_filter'                => String($rp_filter), # hl-sysctl-019, CIS 3.3.1.12
    'net.ipv4.conf.default.rp_filter'            => String($rp_filter), # hl-sysctl-020, CIS 3.3.1.13
    'net.ipv4.conf.all.accept_source_route'      => '0', # hl-sysctl-021, CIS 3.3.1.14
    'net.ipv4.conf.default.accept_source_route'  => '0', # hl-sysctl-022, CIS 3.3.1.15
    'net.ipv4.conf.all.log_martians'             => $martians, # hl-sysctl-023, CIS 3.3.1.16
    'net.ipv4.conf.default.log_martians'         => $martians, # hl-sysctl-024, CIS 3.3.1.17
    'net.ipv4.tcp_syncookies'                    => '1', # hl-sysctl-025, CIS 3.3.1.18
    'net.ipv4.conf.all.route_localnet'           => '0', # hl-sysctl-026, CIS 3.3.1.19
    'net.ipv4.tcp_rfc1337'                       => '1', # hl-sysctl-036, not CIS
  }

  if $manage_ipv6 {
    $ipv6 = {
      'net.ipv6.conf.all.forwarding'              => $forward6, # hl-sysctl-027, CIS 3.3.2.1
      'net.ipv6.conf.default.forwarding'          => $forward6, # hl-sysctl-028, CIS 3.3.2.2
      'net.ipv6.conf.all.accept_redirects'        => '0', # hl-sysctl-029, CIS 3.3.2.3
      'net.ipv6.conf.default.accept_redirects'    => '0', # hl-sysctl-030, CIS 3.3.2.4
      'net.ipv6.conf.all.accept_source_route'     => '0', # hl-sysctl-031, CIS 3.3.2.5
      'net.ipv6.conf.default.accept_source_route' => '0', # hl-sysctl-032, CIS 3.3.2.6
      'net.ipv6.conf.all.accept_ra'               => '0', # hl-sysctl-033, CIS 3.3.2.7
      'net.ipv6.conf.default.accept_ra'           => '0', # hl-sysctl-034, CIS 3.3.2.8
    }
  } else {
    $ipv6 = {}
  }

  ($kernel + $ipv4 + $ipv6).each |String $key, String $value| {
    sysctl { $key:
      value  => $value,
      target => $target,
    }
  }
}
