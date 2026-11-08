# frozen_string_literal: true

require 'spec_helper'

# ID => directory, for 2.4.1.3-2.4.1.8.
CRON_DIRS = {
  'hl-cron-003' => '/etc/cron.hourly',
  'hl-cron-004' => '/etc/cron.daily',
  'hl-cron-005' => '/etc/cron.weekly',
  'hl-cron-006' => '/etc/cron.monthly',
  'hl-cron-007' => '/etc/cron.yearly',
  'hl-cron-008' => '/etc/cron.d',
}.freeze

describe 'baseline::cron' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_package('cron').with_ensure('installed') }

      it 'hl-cron-001: cron is enabled and running' do
        is_expected.to contain_service('cron').with(ensure: 'running', enable: true)
      end

      it 'hl-cron-002: /etc/crontab is root:root 0600' do
        is_expected.to contain_file('/etc/crontab').with(owner: 'root', group: 'root', mode: '0600').without_ensure
      end

      CRON_DIRS.each do |id, dir|
        it "#{id}: #{dir} is root:root 0700" do
          is_expected.to contain_file(dir).with(ensure: 'directory', owner: 'root', group: 'root', mode: '0700')
        end
      end

      it 'hl-cron-009: /etc/cron.allow lists only root' do
        is_expected.to contain_file('/etc/cron.allow')
          .with(ensure: 'file', owner: 'root', group: 'crontab', mode: '0640', content: "root\n")
      end

      it 'fixes /etc/cron.deny access only where it exists' do
        is_expected.to contain_file('/etc/cron.deny').with(owner: 'root', group: 'crontab', mode: '0640').without_ensure
      end
    end
  end
end
