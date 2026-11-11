# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::sudo' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
      let(:sudoers) { '/etc/sudoers' }

      def line(text)
        %r{^#{Regexp.escape(text)}$}
      end

      it { is_expected.to compile.with_all_deps }

      it('hl-sudo-001: sudo is installed') { is_expected.to contain_package('sudo').with_ensure('installed') }

      it 'manages /etc/sudoers, validated by visudo' do
        is_expected.to contain_file(sudoers)
          .with(owner: 'root', group: 'root', mode: '0440', validate_cmd: '/usr/sbin/visudo -c -f %')
          .with_content(line('@includedir /etc/sudoers.d'))
      end

      it 'hl-sudo-002: commands run in a pty' do
        is_expected.to contain_file(sudoers).with_content(line('Defaults        use_pty'))
      end

      it 'hl-sudo-003: logs to /var/log/sudo.log, rotated' do
        is_expected.to contain_file(sudoers).with_content(line('Defaults        logfile="/var/log/sudo.log"'))
        is_expected.to contain_file('/etc/logrotate.d/sudo')
          .with(owner: 'root', group: 'root', mode: '0644')
          .with_content(%r{^/var/log/sudo\.log \{$})
      end

      it 'hl-sudo-004: never skips authentication' do
        is_expected.to contain_file(sudoers).without_content(%r{!authenticate|NOPASSWD})
      end

      it 'hl-sudo-005: authentication lasts 15 minutes' do
        is_expected.to contain_file(sudoers).with_content(line('Defaults        timestamp_timeout=15'))
      end

      it 'hl-sudo-006: su needs membership of the empty sugroup' do
        is_expected.to contain_group('sugroup').with(ensure: 'present', system: true)
        is_expected.to contain_file_line('su pam_wheel').with(
          path: '/etc/pam.d/su',
          line: 'auth       required   pam_wheel.so use_uid group=sugroup',
          after: '^auth\s+sufficient\s+pam_rootok\.so',
        )
      end

      context 'with a shorter timeout in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'sudo_timeout') }

        it { is_expected.to contain_file(sudoers).with_content(line('Defaults        timestamp_timeout=5')) }
      end

      context 'on Ubuntu 25.10 (sudo-rs)' do
        let(:facts) do
          os_facts.merge(os: os_facts[:os].merge('name' => 'Ubuntu', 'release' => { 'full' => '25.10', 'major' => '25.10' }))
        end

        it 'leaves out logfile, which sudo-rs ignores' do
          is_expected.to contain_file(sudoers).without_content(%r{^Defaults\s+logfile})
        end
      end
    end
  end
end
