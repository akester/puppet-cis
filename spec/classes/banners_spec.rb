# frozen_string_literal: true

require 'spec_helper'

# ID => path, for the content (1.6.2, 1.6.3) and access (1.6.7, 1.6.8) rules.
BANNER_FILES = {
  '/etc/issue' => ['hl-banner-002', 'hl-banner-005'],
  '/etc/issue.net' => ['hl-banner-003', 'hl-banner-006'],
}.freeze

describe 'baseline::banners' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-banner-001: empties /etc/motd' do
        is_expected.to contain_file('/etc/motd').with_content('')
      end

      it 'hl-banner-004: /etc/motd is root:root 0644' do
        is_expected.to contain_file('/etc/motd').with(owner: 'root', group: 'root', mode: '0644')
      end

      BANNER_FILES.each do |path, (content_id, access_id)|
        it "#{content_id}: #{path} has the warning and no system information" do
          is_expected.to contain_file(path)
            .with_content(%r{^UNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED$})
            .without_content(%r{\\[mrsv]|debian}i)
        end

        it "#{access_id}: #{path} is root:root 0644" do
          is_expected.to contain_file(path).with(owner: 'root', group: 'root', mode: '0644')
        end
      end

      it 'hl-banner-007: removes the update-motd script that shows the kernel version' do
        is_expected.to contain_file('/etc/update-motd.d/10-uname').with_ensure('absent')
      end

      it 'hl-banner-008: /run/motd.dynamic is root:root 0644 where it exists' do
        is_expected.to contain_file('/run/motd.dynamic').with(owner: 'root', group: 'root', mode: '0644').without_ensure
      end

      it 'renders the default banner exactly' do
        is_expected.to contain_file('/etc/issue').with_content(
          "\n\nUNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED\n\n" \
          "You must have explicit, authorized permission to access or configure this\n" \
          "device. Unauthorized attempts and actions to access or use this system may\n" \
          "result in civil and/or criminal penalties. All activities performed on this\n" \
          "device are logged and monitored.\n\n\n"
        )
      end

      it 'leaves update-notifier alone on Debian (not shipped)' do
        is_expected.not_to contain_service('update-notifier-motd.service')
        is_expected.not_to contain_service('update-notifier-motd.timer')
      end

      context 'on Ubuntu' do
        let(:facts) { os_facts.merge(os: os_facts[:os].merge('name' => 'Ubuntu')) }

        it 'hl-banner-009: masks update-notifier-motd.service' do
          is_expected.to contain_service('update-notifier-motd.service').with(ensure: 'stopped', enable: 'mask')
        end

        it 'hl-banner-010: masks update-notifier-motd.timer' do
          is_expected.to contain_service('update-notifier-motd.timer').with(ensure: 'stopped', enable: 'mask')
        end
      end

      context 'with a custom banner in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'banners_custom') }

        it 'hl-banner-002: uses it for /etc/issue' do
          is_expected.to contain_file('/etc/issue').with_content("Authorized users only.\n")
        end
      end

      context 'with a getty escape in the banner' do
        let(:facts) { os_facts.merge(hiera_case: 'banners_escape') }

        it { is_expected.to compile.and_raise_error(%r{must not contain getty escapes}) }
      end
    end
  end
end
