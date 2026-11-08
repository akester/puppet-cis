# frozen_string_literal: true

# Active Linux security modules, in load order, from securityfs (e.g.
# ["lockdown", "capability", "landlock", "yama", "apparmor"]). Yama and
# AppArmor only register their sysctls while active, so baseline::sysctl
# skips their keys when they're missing here. Unset where securityfs isn't
# mounted (e.g. inside containers).
Facter.add(:baseline_lsm) do
  confine kernel: 'Linux'

  setcode do
    path = '/sys/kernel/security/lsm'
    File.read(path).strip.split(',') if File.readable?(path)
  end
end
