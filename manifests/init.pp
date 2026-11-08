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
#   Manage apt key directory permissions and repository security settings
#   (baseline::apt).
#
# @param manage_apparmor
#   Install the AppArmor userspace packages (baseline::apparmor).
#
# @param manage_bootloader
#   Manage ownership and mode of the GRUB config (baseline::bootloader).
#
# @param manage_process
#   Remove prelink and apport, and turn off core dumps (baseline::process).
#
# @param manage_banners
#   Manage /etc/issue, /etc/issue.net and /etc/motd (baseline::banners).
#
# @param manage_services
#   Remove server and client packages CIS chapter 2 says not to run
#   (baseline::services).
#
# @param manage_cron
#   Keep cron running and its config root-only (baseline::cron).
#
# @param manage_at
#   Limit `at` to the users in /etc/at.allow (baseline::at).
#
# @param services_allow
#   Services baseline::services leaves alone on this host, added to
#   `baseline::services::allow`. For a profile that declares `baseline` and
#   works out the exceptions from the host's other classes.
#
# @example
#   include baseline
class baseline (
  Boolean          $manage_sysctl     = true,
  Boolean          $manage_kmod       = true,
  Boolean          $manage_mounts     = true,
  Boolean          $manage_apt        = true,
  Boolean          $manage_apparmor   = true,
  Boolean          $manage_bootloader = true,
  Boolean          $manage_process    = true,
  Boolean          $manage_banners    = true,
  Boolean          $manage_services   = true,
  Boolean          $manage_cron       = true,
  Boolean          $manage_at         = true,
  Array[String[1]] $services_allow    = [],
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

  if $manage_apparmor {
    contain baseline::apparmor
  }

  if $manage_bootloader {
    contain baseline::bootloader
  }

  if $manage_process {
    contain baseline::process
  }

  if $manage_banners {
    contain baseline::banners
  }

  if $manage_services {
    contain baseline::services
  }

  if $manage_cron {
    contain baseline::cron
  }

  if $manage_at {
    contain baseline::at
  }
}
