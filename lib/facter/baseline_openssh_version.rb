# frozen_string_literal: true

# Upstream version of the installed openssh-server package, e.g. "10.0" for
# Debian's 1:10.0p1-7. Unset when the package isn't installed.
Facter.add(:baseline_openssh_version) do
  confine kernel: 'Linux'
  setcode do
    version = Facter::Core::Execution.execute(
      "dpkg-query -W -f='${Version}' openssh-server 2>/dev/null",
      on_fail: nil,
    )
    version.to_s[%r{\A(?:\d+:)?(\d+\.\d+)}, 1]
  end
end
