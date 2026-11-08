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
# @param manage_mounts
#   Manage the /tmp, /var/tmp and /dev/shm tmpfs mounts (baseline::mounts).
#
# @param manage_apt
#   Manage ownership and mode of the apt key directories (baseline::apt).
#
# @example
#   include baseline
class baseline (
  Boolean $manage_sysctl = true,
  Boolean $manage_kmod   = true,
  Boolean $manage_mounts = true,
  Boolean $manage_apt    = true,
) {
  if $manage_sysctl {
    contain baseline::sysctl
  }

  if $manage_kmod {
    contain baseline::kmod
  }

  if $manage_mounts {
    contain baseline::mounts
  }

  if $manage_apt {
    contain baseline::apt
  }
}
