# @summary OS hardening baseline, aligned with the CIS Debian Linux 13 Benchmark.
#
# Entry point for the baseline. Subclasses are added one area at a time
# (sysctl, kmod, pam, ssh, ...); each will be toggled by its own flag here.
#
# @example
#   include baseline
class baseline {
}
