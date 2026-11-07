# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::sysctl' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:target) { '/etc/sysctl.d/60-baseline.conf' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-sysctl-001: restricts hardlink creation' do
        is_expected.to contain_sysctl('fs.protected_hardlinks').with(value: '1', target: target)
      end

      it 'hl-sysctl-002: restricts following symlinks' do
        is_expected.to contain_sysctl('fs.protected_symlinks').with(value: '1', target: target)
      end

      it 'hl-sysctl-003: restricts ptrace to CAP_SYS_PTRACE' do
        is_expected.to contain_sysctl('kernel.yama.ptrace_scope').with(value: '2', target: target)
      end

      it 'hl-sysctl-004: disables core dumps of setuid programs' do
        is_expected.to contain_sysctl('fs.suid_dumpable').with(value: '0', target: target)
      end

      it 'hl-sysctl-005: restricts dmesg to CAP_SYSLOG' do
        is_expected.to contain_sysctl('kernel.dmesg_restrict').with(value: '1', target: target)
      end

      it 'hl-sysctl-006: hides kernel pointers from unprivileged users' do
        is_expected.to contain_sysctl('kernel.kptr_restrict').with(value: '1', target: target)
      end

      it 'hl-sysctl-007: enables full address space randomization' do
        is_expected.to contain_sysctl('kernel.randomize_va_space').with(value: '2', target: target)
      end

      context 'with ptrace_scope: 1 in Hiera' do
        let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
        let(:facts) { os_facts.merge(hiera_case: 'ptrace_scope_1') }

        it 'hl-sysctl-003: allows tracing descendants' do
          is_expected.to contain_sysctl('kernel.yama.ptrace_scope').with_value('1')
        end
      end
    end
  end
end
