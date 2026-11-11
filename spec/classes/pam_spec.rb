# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::pam' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

      it { is_expected.to compile.with_all_deps }

      {
        'hl-pam-001' => 'libpam-runtime',
        'hl-pam-002' => 'libpam-modules',
        'hl-pam-003' => 'libpam-pwquality',
        'hl-pam-004' => 'cracklib-runtime',
      }.each do |id, pkg|
        it("#{id}: #{pkg} is installed") { is_expected.to contain_package(pkg).with_ensure('installed') }
      end

      {
        'faillock' => %r{^Priority: 0\n.*^\s+\[default=die\]\s+pam_faillock\.so authfail$}m,
        'faillock_notify' => %r{^Priority: 1024\n.*^\s+requisite\s+pam_faillock\.so preauth$.*^\s+required\s+pam_faillock\.so$}m,
        'pwhistory' => %r{^Priority: 1024\n.*^\s+requisite\s+pam_pwhistory\.so use_authtok$}m,
      }.each do |name, content|
        it "hl-pam-006, hl-pam-008: the #{name} profile" do
          is_expected.to contain_file("/usr/share/pam-configs/#{name}")
            .with(owner: 'root', group: 'root', mode: '0644', content: content)
            .that_notifies('Exec[pam-auth-update]')
        end
      end

      context 'with the unix profile' do
        let(:unix) { catalogue.resource('File', '/usr/share/pam-configs/unix')[:content] }

        it { is_expected.to contain_file('/usr/share/pam-configs/unix').that_notifies('Exec[pam-auth-update]') }
        it('hl-pam-020: has no nullok') { expect(unix).not_to match(%r{nullok}) }
        it('hl-pam-021: has no remember') { expect(unix).not_to match(%r{remember}) }

        it 'hl-pam-022, hl-pam-023: hashes with yescrypt, using the checked password' do
          expect(unix).to match(%r{^Password:\n\s+\[success=end default=ignore\]\s+pam_unix\.so obscure use_authtok try_first_pass yescrypt$})
        end

        it 'still authenticates with pam_unix' do
          expect(unix).to match(%r{^Auth:\n\s+\[success=end default=ignore\]\s+pam_unix\.so try_first_pass$})
        end
      end

      it 'hl-pam-005..008: enables the profiles with pam-auth-update' do
        is_expected.to contain_exec('pam-auth-update').with(
          command: '/usr/sbin/pam-auth-update --enable unix faillock faillock_notify pwquality pwhistory',
          refreshonly: true,
        ).that_subscribes_to('Package[libpam-pwquality]')
      end

      it 'hl-pam-009, hl-pam-010: locks after 5 failures for 15 minutes, root exempt' do
        is_expected.to contain_file('/etc/security/faillock.conf')
          .with(owner: 'root', group: 'root', mode: '0644')
          .with_content(%r{^deny = 5$})
          .with_content(%r{^unlock_time = 900$})
          .without_content(%r{even_deny_root|root_unlock_time})
      end

      context 'with faillock values in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'faillock_never_unlock') }

        it do
          is_expected.to contain_file('/etc/security/faillock.conf')
            .with_content(%r{^deny = 3$})
            .with_content(%r{^unlock_time = 0$})
        end
      end

      {
        'hl-pam-011' => 'difok = 2',
        'hl-pam-012' => 'minlen = 14',
        'hl-pam-013' => 'maxrepeat = 3',
        'hl-pam-014' => 'maxsequence = 3',
        'hl-pam-015' => 'dictcheck = 1',
        'hl-pam-016' => 'enforcing = 1',
        'hl-pam-017' => 'enforce_for_root',
      }.each do |id, setting|
        it "#{id}: pwquality sets #{setting.split.first}" do
          is_expected.to contain_file('/etc/security/pwquality.conf.d/50-baseline.conf')
            .with(owner: 'root', group: 'root', mode: '0644')
            .with_content(%r{^#{Regexp.escape(setting)}$})
        end
      end

      it 'leaves complexity to length and the dictionary check' do
        is_expected.to contain_file('/etc/security/pwquality.conf.d/50-baseline.conf')
          .without_content(%r{minclass|credit})
      end

      it 'hl-pam-018, hl-pam-019: remembers 24 passwords, root included' do
        is_expected.to contain_file('/etc/security/pwhistory.conf')
          .with(owner: 'root', group: 'root', mode: '0644')
          .with_content(%r{^remember = 24$})
          .with_content(%r{^enforce_for_root$})
      end

      it 'leaves /etc/pam.d/common-* to pam-auth-update' do
        ['auth', 'account', 'password', 'session', 'session-noninteractive'].each do |f|
          is_expected.not_to contain_file("/etc/pam.d/common-#{f}")
        end
      end
    end
  end
end
