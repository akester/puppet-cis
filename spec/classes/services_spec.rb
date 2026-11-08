# frozen_string_literal: true

require 'spec_helper'

DHCP_PACKAGES = ['kea-dhcp4-server', 'kea-dhcp6-server', 'kea-dhcp-ddns-server', 'isc-dhcp-server'].freeze

describe 'baseline::services' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-service-001: purges autofs' do
        is_expected.to contain_package('autofs').with_ensure('purged')
      end

      it 'hl-service-002: purges avahi-daemon' do
        is_expected.to contain_package('avahi-daemon').with_ensure('purged')
      end

      DHCP_PACKAGES.each do |pkg|
        it "hl-service-003: purges #{pkg}" do
          is_expected.to contain_package(pkg).with_ensure('purged')
        end
      end

      it 'hl-service-004: purges bind9' do
        is_expected.to contain_package('bind9').with_ensure('purged')
      end

      it 'hl-service-005: purges dnsmasq' do
        is_expected.to contain_package('dnsmasq').with_ensure('purged')
      end

      ['vsftpd', 'proftpd-core', 'pure-ftpd'].each do |pkg|
        it "hl-service-006: purges #{pkg}" do
          is_expected.to contain_package(pkg).with_ensure('purged')
        end
      end

      it 'hl-service-007: purges slapd' do
        is_expected.to contain_package('slapd').with_ensure('purged')
      end

      ['dovecot-imapd', 'dovecot-pop3d', 'cyrus-imapd', 'cyrus-pop3d'].each do |pkg|
        it "hl-service-008: purges #{pkg}" do
          is_expected.to contain_package(pkg).with_ensure('purged')
        end
      end

      it 'hl-service-009: purges nfs-kernel-server' do
        is_expected.to contain_package('nfs-kernel-server').with_ensure('purged')
      end

      it 'hl-service-010: purges ypserv' do
        is_expected.to contain_package('ypserv').with_ensure('purged')
      end

      it 'hl-service-011: purges cups' do
        is_expected.to contain_package('cups').with_ensure('purged')
      end

      it 'hl-service-012: masks rpcbind' do
        ['rpcbind.service', 'rpcbind.socket'].each do |unit|
          is_expected.to contain_service(unit).with(ensure: 'stopped', enable: 'mask')
        end
        is_expected.not_to contain_package('rpcbind')
      end

      it 'hl-service-013: masks the rsync daemon and keeps the package' do
        is_expected.to contain_service('rsync.service').with(ensure: 'stopped', enable: 'mask')
        is_expected.not_to contain_package('rsync')
      end

      it 'hl-service-014: purges samba' do
        is_expected.to contain_package('samba').with_ensure('purged')
      end

      it 'hl-service-015: purges snmpd' do
        is_expected.to contain_package('snmpd').with_ensure('purged')
      end

      ['telnetd', 'telnetd-ssl', 'inetutils-telnetd'].each do |pkg|
        it "hl-service-016: purges #{pkg}" do
          is_expected.to contain_package(pkg).with_ensure('purged')
        end
      end

      ['tftpd-hpa', 'atftpd'].each do |pkg|
        it "hl-service-017: purges #{pkg}" do
          is_expected.to contain_package(pkg).with_ensure('purged')
        end
      end

      it 'hl-service-018: purges squid' do
        is_expected.to contain_package('squid').with_ensure('purged')
      end

      it 'hl-service-019: purges apache2' do
        is_expected.to contain_package('apache2').with_ensure('purged')
      end

      it 'hl-service-020: purges nginx' do
        is_expected.to contain_package('nginx').with_ensure('purged')
      end

      it 'hl-service-021: purges xinetd' do
        is_expected.to contain_package('xinetd').with_ensure('purged')
      end

      {
        'hl-client-001' => ['nis'],
        'hl-client-002' => ['rsh-client'],
        'hl-client-003' => ['talk', 'inetutils-talk'],
        'hl-client-004' => ['telnet', 'inetutils-telnet', 'telnet-ssl'],
        'hl-client-005' => ['ldap-utils'],
        'hl-client-006' => ['ftp', 'tnftp', 'atftp', 'inetutils-ftp', 'ftp-ssl'],
      }.each do |id, pkgs|
        pkgs.each do |pkg|
          it "#{id}: purges #{pkg}" do
            is_expected.to contain_package(pkg).with_ensure('purged')
          end
        end
      end

      context 'with ldap-client allowed' do
        let(:pre_condition) { "class { 'baseline': services_allow => ['ldap-client'] }" }

        it { is_expected.not_to contain_package('ldap-utils') }
        it { is_expected.to contain_package('slapd').with_ensure('purged') }
      end

      context 'with rpcbind allowed' do
        let(:pre_condition) { "class { 'baseline': services_allow => ['rpcbind'] }" }

        it { is_expected.not_to contain_service('rpcbind.service') }
        it { is_expected.not_to contain_service('rpcbind.socket') }
        it { is_expected.to contain_service('rsync.service').with_enable('mask') }
      end

      context 'with dhcp allowed' do
        let(:facts) { os_facts.merge(hiera_case: 'services_allow_dhcp') }

        it 'leaves the DHCP server packages alone' do
          DHCP_PACKAGES.each { |pkg| is_expected.not_to contain_package(pkg) }
        end

        it { is_expected.to contain_package('avahi-daemon').with_ensure('purged') }
      end

      context 'with autofs in baseline::services_allow' do
        let(:pre_condition) { "class { 'baseline': services_allow => ['autofs'] }" }

        it { is_expected.not_to contain_package('autofs') }
        it { is_expected.to contain_package('avahi-daemon').with_ensure('purged') }
      end

      context 'with services_allow and Hiera allow together' do
        let(:facts) { os_facts.merge(hiera_case: 'services_allow_dhcp') }
        let(:pre_condition) { "class { 'baseline': services_allow => ['autofs'] }" }

        it 'leaves both alone' do
          is_expected.not_to contain_package('autofs')
          DHCP_PACKAGES.each { |pkg| is_expected.not_to contain_package(pkg) }
        end
      end

      context 'with an unknown service in services_allow' do
        let(:pre_condition) { "class { 'baseline': services_allow => ['bogus'] }" }

        it { is_expected.to compile.and_raise_error(%r{aren't in the list: bogus}) }
      end

      context 'with an unknown service in allow' do
        let(:facts) { os_facts.merge(hiera_case: 'services_allow_typo') }

        it { is_expected.to compile.and_raise_error(%r{aren't in the list: dhcpd}) }
      end
    end
  end
end
