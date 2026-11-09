# frozen_string_literal: true

require 'spec_helper'

# ID => line expected in sshd_config, for the settings with a fixed value.
SSHD_SETTINGS = {
  'hl-ssh-006' => 'Banner /etc/issue.net',
  'hl-ssh-007' => 'Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr',
  'hl-ssh-010' => 'GSSAPIAuthentication no',
  'hl-ssh-011' => 'HostbasedAuthentication no',
  'hl-ssh-012' => 'IgnoreRhosts yes',
  'hl-ssh-015' => 'LoginGraceTime 30',
  'hl-ssh-016' => 'LogLevel VERBOSE',
  'hl-ssh-017' => 'MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com',
  'hl-ssh-018' => 'MaxAuthTries 3',
  'hl-ssh-019' => 'MaxSessions 2',
  'hl-ssh-020' => 'MaxStartups 10:30:60',
  'hl-ssh-021' => 'PermitEmptyPasswords no',
  'hl-ssh-023' => 'PermitUserEnvironment no',
  'hl-ssh-024' => 'UsePAM yes',
}.freeze

describe 'baseline::ssh' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(baseline_openssh_version: '10.0') }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
      let(:config) { '/etc/ssh/sshd_config' }

      def line(text)
        %r{^#{Regexp.escape(text)}$}
      end

      it { is_expected.to compile.with_all_deps }

      it 'hl-ssh-001: sshd_config is root:root 0600 and validated' do
        is_expected.to contain_file(config)
          .with(owner: 'root', group: 'root', mode: '0600', validate_cmd: '/usr/sbin/sshd -t -f %')
          .that_notifies('Service[ssh]')
      end

      it 'has no Include, so drop-ins are ignored' do
        is_expected.to contain_file(config).without_content(%r{^\s*Include}i)
      end

      it 'hl-ssh-002: sshd_config.d and its files are root-only' do
        is_expected.to contain_file('/etc/ssh/sshd_config.d')
          .with(ensure: 'directory', owner: 'root', group: 'root', mode: '0600', recurse: true)
      end

      ['ed25519', 'rsa'].each do |type|
        it "hl-ssh-003: the #{type} private host key is root:root 0600" do
          is_expected.to contain_file("/etc/ssh/ssh_host_#{type}_key").with(owner: 'root', group: 'root', mode: '0600').without_ensure
        end

        it "hl-ssh-004: the #{type} public host key is root:root 0644" do
          is_expected.to contain_file("/etc/ssh/ssh_host_#{type}_key.pub").with(owner: 'root', group: 'root', mode: '0644').without_ensure
        end
      end

      it 'hl-ssh-005: only sudo and ssh may log in' do
        is_expected.to contain_file(config).with_content(line('AllowGroups sudo ssh'))
      end

      SSHD_SETTINGS.each do |id, setting|
        it "#{id}: sets #{setting.split.first}" do
          is_expected.to contain_file(config).with_content(line(setting))
        end
      end

      it 'hl-ssh-008: sets ClientAliveInterval and ClientAliveCountMax' do
        is_expected.to contain_file(config)
          .with_content(line('ClientAliveInterval 300'))
          .with_content(line('ClientAliveCountMax 2'))
      end

      it 'hl-ssh-009: disables forwarding, X11 included' do
        is_expected.to contain_file(config)
          .with_content(line('DisableForwarding yes'))
          .with_content(line('X11Forwarding no'))
      end

      it 'hl-ssh-013, hl-ssh-014: offers the post-quantum kex on OpenSSH 9.9 and later' do
        is_expected.to contain_file(config).with_content(
          line('KexAlgorithms mlkem768x25519-sha256,sntrup761x25519-sha512,sntrup761x25519-sha512@openssh.com,' \
               'curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256'),
        )
      end

      it 'hl-ssh-022: refuses root logins' do
        is_expected.to contain_file(config).with_content(line('PermitRootLogin no'))
      end

      it 'listens on port 22' do
        is_expected.to contain_file(config).with_content(line('Port 22'))
      end

      it { is_expected.to contain_service('ssh').with(ensure: 'running', enable: true) }

      context 'with OpenSSH before 9.9' do
        let(:facts) { os_facts.merge(baseline_openssh_version: '9.6') }

        it 'hl-ssh-014: offers only the sntrup kex' do
          is_expected.to contain_file(config).with_content(
            line('KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256'),
          )
        end
      end

      context 'before the OpenSSH version is known' do
        let(:facts) { os_facts.merge(baseline_openssh_version: nil) }

        it { is_expected.to contain_file(config).without_content(%r{mlkem}) }
      end

      context 'with overrides in Hiera' do
        let(:facts) { os_facts.merge(baseline_openssh_version: '10.0', hiera_case: 'ssh_overrides') }

        it 'listens on each port' do
          is_expected.to contain_file(config).with_content(line('Port 22')).with_content(line('Port 2222'))
        end

        it { is_expected.to contain_file(config).with_content(line('PermitRootLogin yes')) }
        it { is_expected.to contain_file(config).with_content(line('AllowGroups admins')) }

        it 'keeps X11 off with forwarding allowed' do
          is_expected.to contain_file(config)
            .with_content(line('DisableForwarding no'))
            .with_content(line('X11Forwarding no'))
        end
      end
    end
  end
end
