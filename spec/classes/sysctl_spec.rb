# frozen_string_literal: true

require 'spec_helper'

# Default value of every control: ID => [key, value, description].
SYSCTL_DEFAULTS = {
  'hl-sysctl-001' => ['fs.protected_hardlinks', '1', 'restricts hardlink creation'],
  'hl-sysctl-002' => ['fs.protected_symlinks', '1', 'restricts following symlinks'],
  'hl-sysctl-003' => ['kernel.yama.ptrace_scope', '2', 'restricts ptrace to CAP_SYS_PTRACE'],
  'hl-sysctl-004' => ['fs.suid_dumpable', '0', 'disables core dumps of setuid programs'],
  'hl-sysctl-005' => ['kernel.dmesg_restrict', '1', 'restricts dmesg to CAP_SYSLOG'],
  'hl-sysctl-006' => ['kernel.kptr_restrict', '1', 'hides kernel pointers from unprivileged users'],
  'hl-sysctl-007' => ['kernel.randomize_va_space', '2', 'enables full address space randomization'],
  'hl-sysctl-008' => ['net.ipv4.ip_forward', '0', 'disables IPv4 forwarding'],
  'hl-sysctl-009' => ['net.ipv4.conf.all.forwarding', '0', 'disables IPv4 forwarding on all interfaces'],
  'hl-sysctl-010' => ['net.ipv4.conf.default.forwarding', '0', 'disables IPv4 forwarding on new interfaces'],
  'hl-sysctl-011' => ['net.ipv4.conf.all.send_redirects', '0', 'does not send ICMP redirects'],
  'hl-sysctl-012' => ['net.ipv4.conf.default.send_redirects', '0', 'does not send ICMP redirects on new interfaces'],
  'hl-sysctl-013' => ['net.ipv4.icmp_ignore_bogus_error_responses', '1', 'ignores bogus ICMP error responses'],
  'hl-sysctl-014' => ['net.ipv4.icmp_echo_ignore_broadcasts', '1', 'ignores broadcast pings'],
  'hl-sysctl-015' => ['net.ipv4.conf.all.accept_redirects', '0', 'ignores ICMP redirects'],
  'hl-sysctl-016' => ['net.ipv4.conf.default.accept_redirects', '0', 'ignores ICMP redirects on new interfaces'],
  'hl-sysctl-017' => ['net.ipv4.conf.all.secure_redirects', '0', 'ignores gateway ICMP redirects'],
  'hl-sysctl-018' => ['net.ipv4.conf.default.secure_redirects', '0', 'ignores gateway ICMP redirects on new interfaces'],
  'hl-sysctl-019' => ['net.ipv4.conf.all.rp_filter', '1', 'enables strict reverse path filtering'],
  'hl-sysctl-020' => ['net.ipv4.conf.default.rp_filter', '1', 'enables strict reverse path filtering on new interfaces'],
  'hl-sysctl-021' => ['net.ipv4.conf.all.accept_source_route', '0', 'rejects source-routed packets'],
  'hl-sysctl-022' => ['net.ipv4.conf.default.accept_source_route', '0', 'rejects source-routed packets on new interfaces'],
  'hl-sysctl-023' => ['net.ipv4.conf.all.log_martians', '1', 'logs martian packets'],
  'hl-sysctl-024' => ['net.ipv4.conf.default.log_martians', '1', 'logs martian packets on new interfaces'],
  'hl-sysctl-025' => ['net.ipv4.tcp_syncookies', '1', 'enables TCP SYN cookies'],
  'hl-sysctl-026' => ['net.ipv4.conf.all.route_localnet', '0', 'does not route to loopback addresses'],
  'hl-sysctl-027' => ['net.ipv6.conf.all.forwarding', '0', 'disables IPv6 forwarding'],
  'hl-sysctl-028' => ['net.ipv6.conf.default.forwarding', '0', 'disables IPv6 forwarding on new interfaces'],
  'hl-sysctl-029' => ['net.ipv6.conf.all.accept_redirects', '0', 'ignores ICMPv6 redirects'],
  'hl-sysctl-030' => ['net.ipv6.conf.default.accept_redirects', '0', 'ignores ICMPv6 redirects on new interfaces'],
  'hl-sysctl-031' => ['net.ipv6.conf.all.accept_source_route', '0', 'rejects source-routed IPv6 packets'],
  'hl-sysctl-032' => ['net.ipv6.conf.default.accept_source_route', '0', 'rejects source-routed IPv6 packets on new interfaces'],
  'hl-sysctl-033' => ['net.ipv6.conf.all.accept_ra', '0', 'ignores router advertisements'],
  'hl-sysctl-034' => ['net.ipv6.conf.default.accept_ra', '0', 'ignores router advertisements on new interfaces'],
  'hl-sysctl-035' => ['kernel.sysrq', '0', 'disables the magic SysRq key'],
  'hl-sysctl-036' => ['net.ipv4.tcp_rfc1337', '1', 'protects TIME_WAIT sockets from RST assassination'],
  'hl-sysctl-037' => ['kernel.apparmor_restrict_unprivileged_unconfined', '1', 'stops unconfined users switching AppArmor profiles'],
}.freeze

describe 'baseline::sysctl' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to have_sysctl_resource_count(SYSCTL_DEFAULTS.size) }

      SYSCTL_DEFAULTS.each do |id, (key, value, description)|
        it "#{id}: #{description}" do
          is_expected.to contain_sysctl(key).with(value: value, target: '/etc/sysctl.d/60-baseline.conf')
        end
      end

      context 'with ptrace_scope: 1 in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'ptrace_scope_1') }

        it 'hl-sysctl-003: allows tracing descendants' do
          is_expected.to contain_sysctl('kernel.yama.ptrace_scope').with_value('1')
        end
      end

      context 'with ipv4_forwarding: true in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'forwarding') }

        it 'hl-sysctl-008: enables IPv4 forwarding' do
          is_expected.to contain_sysctl('net.ipv4.ip_forward').with_value('1')
        end

        it 'hl-sysctl-023: stops logging martians by default' do
          is_expected.to contain_sysctl('net.ipv4.conf.all.log_martians').with_value('0')
        end

        it 'hl-sysctl-024: stops logging martians on new interfaces by default' do
          is_expected.to contain_sysctl('net.ipv4.conf.default.log_martians').with_value('0')
        end
      end

      context 'with ipv4_forwarding and log_martians both true in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'forwarding_martians') }

        it 'hl-sysctl-023: logs martians when explicitly asked' do
          is_expected.to contain_sysctl('net.ipv4.conf.all.log_martians').with_value('1')
        end
      end

      context 'with forwarding, loose rp_filter and no martian logging in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'router') }

        {
          'hl-sysctl-008' => ['net.ipv4.ip_forward', '1'],
          'hl-sysctl-009' => ['net.ipv4.conf.all.forwarding', '1'],
          'hl-sysctl-010' => ['net.ipv4.conf.default.forwarding', '1'],
          'hl-sysctl-019' => ['net.ipv4.conf.all.rp_filter', '2'],
          'hl-sysctl-020' => ['net.ipv4.conf.default.rp_filter', '2'],
          'hl-sysctl-023' => ['net.ipv4.conf.all.log_martians', '0'],
          'hl-sysctl-024' => ['net.ipv4.conf.default.log_martians', '0'],
          'hl-sysctl-027' => ['net.ipv6.conf.all.forwarding', '1'],
          'hl-sysctl-028' => ['net.ipv6.conf.default.forwarding', '1'],
        }.each do |id, (key, value)|
          it "#{id}: sets #{key} to #{value}" do
            is_expected.to contain_sysctl(key).with_value(value)
          end
        end
      end

      context 'with Yama and AppArmor both active' do
        let(:facts) { os_facts.merge(baseline_lsm: %w[lockdown capability landlock yama apparmor]) }

        it { is_expected.to have_sysctl_resource_count(SYSCTL_DEFAULTS.size) }
      end

      context 'on a kernel without Yama or AppArmor (Raspberry Pi)' do
        let(:facts) { os_facts.merge(baseline_lsm: %w[capability]) }

        it 'hl-sysctl-003: skips kernel.yama.ptrace_scope' do
          is_expected.not_to contain_sysctl('kernel.yama.ptrace_scope')
        end

        it 'hl-sysctl-037: skips kernel.apparmor_restrict_unprivileged_unconfined' do
          is_expected.not_to contain_sysctl('kernel.apparmor_restrict_unprivileged_unconfined')
        end

        it { is_expected.to have_sysctl_resource_count(SYSCTL_DEFAULTS.size - 2) }
      end

      context 'with manage_ipv6: false in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'no_ipv6') }

        it 'hl-sysctl-027..034: leaves IPv6 parameters alone' do
          is_expected.to have_sysctl_resource_count(SYSCTL_DEFAULTS.count { |_, (key, _)| !key.start_with?('net.ipv6.') })
        end
      end
    end
  end
end
