# @summary OS hardening baseline, aligned with the CIS Debian Linux 13 Benchmark.
#
# Entry point for the baseline. Subclasses are added one area at a time
# (sysctl, kmod, pam, ssh, ...); each is toggled by its own flag here.
#
# @param manage_sysctl
#   Manage kernel parameters (baseline::sysctl). Set false in containers
#   (e.g. LXC), where the host owns the kernel.
#
# @param manage_kmod
#   Manage the kernel module deny list (baseline::kmod).
#
# @example
#   include baseline
class baseline (
  Boolean $manage_sysctl = true,
  Boolean $manage_kmod   = true,
) {
  if $manage_sysctl {
    contain baseline::sysctl
  }

  if $manage_kmod {
    contain baseline::kmod
  }
}
