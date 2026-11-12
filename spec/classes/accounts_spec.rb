# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::accounts' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

      def users(filter)
        "/usr/bin/awk -F: '$2 ~ /^\\$.+\\$/ && #{filter} { print $1 }' /etc/shadow"
      end

      it { is_expected.to compile.with_all_deps }

      {
        'hl-acct-001' => ['PASS_MAX_DAYS', 'PASS_MAX_DAYS 365'],
        'hl-acct-003' => ['PASS_WARN_AGE', 'PASS_WARN_AGE 7'],
        'hl-acct-005' => ['ENCRYPT_METHOD', 'ENCRYPT_METHOD YESCRYPT'],
      }.each do |id, (key, line)|
        it "#{id}: login.defs sets #{line}" do
          is_expected.to contain_file_line("login.defs #{key}")
            .with(path: '/etc/login.defs', line: line, match: "^\\s*#?\\s*#{key}\\s")
        end
      end

      it 'hl-acct-006: new accounts lock 45 days after expiry' do
        is_expected.to contain_file_line('useradd INACTIVE')
          .with(path: '/etc/default/useradd', line: 'INACTIVE=45', match: '^\s*#?\s*INACTIVE=')
      end

      {
        'hl-acct-002' => ['maxdays', '($5 > 365 || $5 < 1)', 365],
        'hl-acct-004' => ['warndays', '$6 < 7', 7],
      }.each do |id, (option, filter, value)|
        it "#{id}: chage --#{option} on accounts with a password, out of range" do
          is_expected.to contain_exec("chage --#{option}").with(
            command: "#{users(filter)} | /usr/bin/xargs -r -n1 /usr/bin/chage --#{option} #{value}",
            onlyif: "#{users(filter)} | /usr/bin/grep -q .",
            provider: 'shell',
          )
        end
      end

      it 'leaves existing accounts\' inactive period alone' do
        is_expected.not_to contain_exec('chage --inactive')
      end

      it 'hl-acct-008: root is locked only if its password is empty' do
        is_expected.to contain_exec('lock root without a password')
          .with_command('/usr/sbin/usermod -L root')
          .with_onlyif(%r{\$1 == "root" && \$2 == ""})
      end

      ['/root/.profile', '/root/.bashrc'].each do |rc|
        it "hl-acct-009: no umask in #{rc}" do
          is_expected.to contain_file_line("#{rc} umask")
            .with(ensure: 'absent', path: rc, match: '^\s*umask\s', match_for_absence: true, multiple: true)
        end
      end

      it 'hl-acct-010: system accounts with a valid shell get nologin' do
        is_expected.to contain_exec('nologin for system accounts')
          .with(
            command: %r{\(\$3 < min \|\| \$3 == 65534\) && \(\$NF in valid\).*/etc/shells /etc/passwd \| xargs -r -n1 usermod -s /usr/sbin/nologin$}m,
            onlyif: %r{/etc/shells /etc/passwd \| grep -q \.$},
            environment: ['EXEMPT=^(root|halt|sync|shutdown|nfsnobody)$'],
            provider: 'shell',
          )
      end

      it 'hl-acct-011: accounts without a valid shell are locked' do
        is_expected.to contain_exec('lock accounts without a shell')
          .with(
            command: %r{\$2 !~ /\^\[!\*\]/.*/etc/shells /etc/passwd /etc/shadow \| xargs -r -n1 usermod -L$}m,
            provider: 'shell',
          )
          .that_requires('Exec[nologin for system accounts]')
      end

      ['nologin for system accounts', 'lock accounts without a shell'].each do |name|
        it "#{name} is one line" do
          expect(catalogue.resource('Exec', name)[:command]).not_to include("\n")
        end
      end

      context 'with Hiera overrides' do
        let(:facts) { os_facts.merge(hiera_case: 'accounts_custom') }

        it { is_expected.to contain_file_line('login.defs PASS_MAX_DAYS').with_line('PASS_MAX_DAYS 90') }
        it { is_expected.to contain_file_line('login.defs PASS_WARN_AGE').with_line('PASS_WARN_AGE 14') }
        it { is_expected.to contain_file_line('useradd INACTIVE').with_line('INACTIVE=30') }
        it { is_expected.to contain_exec('chage --maxdays').with_command(%r{\(\$5 > 90 \|\| \$5 < 1\).*--maxdays 90$}) }
        it { is_expected.to contain_exec('chage --warndays').with_command(%r{\$6 < 14 .*--warndays 14$}) }

        it 'hl-acct-010: shell_allow keeps those accounts\' shells' do
          is_expected.to contain_exec('nologin for system accounts')
            .with_environment(['EXEMPT=^(root|halt|sync|shutdown|nfsnobody|git|gitlab-runner)$'])
        end
      end
    end
  end
end
