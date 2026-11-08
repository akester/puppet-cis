# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::process' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-process-001: purges prelink' do
        is_expected.to contain_package('prelink').with_ensure('purged')
      end

      it 'hl-process-002: purges apport' do
        is_expected.to contain_package('apport').with_ensure('purged')
      end

      it 'hl-process-003: sets a hard core size limit of 0 for all users' do
        is_expected.to contain_file('/etc/security/limits.d/60-baseline.conf')
          .with(owner: 'root', group: 'root', mode: '0644')
          .with_content(%r{^\* hard core 0$})
      end

      it { is_expected.to contain_file('/etc/systemd/coredump.conf.d').with_ensure('directory') }

      it 'hl-process-004: sets systemd-coredump ProcessSizeMax=0' do
        is_expected.to contain_file('/etc/systemd/coredump.conf.d/60-baseline.conf')
          .with(owner: 'root', group: 'root', mode: '0644')
          .with_content(%r{^\[Coredump\]\n(.*\n)*ProcessSizeMax=0$})
      end

      it 'hl-process-005: sets systemd-coredump Storage=none' do
        is_expected.to contain_file('/etc/systemd/coredump.conf.d/60-baseline.conf')
          .with_content(%r{^\[Coredump\]\n(.*\n)*Storage=none$})
      end
    end
  end
end
