# frozen_string_literal: true

require 'spec_helper'

# ID => directory
APT_DIRECTORIES = {
  'hl-apt-001' => '/etc/apt/trusted.gpg.d',
  'hl-apt-002' => '/usr/share/keyrings',
}.freeze

# ID => [apt.conf key, value]
APT_SETTINGS = {
  'hl-apt-003' => ['Acquire::AllowInsecureRepositories', '0'],
  'hl-apt-004' => ['Acquire::AllowWeakRepositories', '0'],
  'hl-apt-005' => ['Acquire::AllowDowngradeToInsecureRepositories', '0'],
  'hl-apt-006' => ['Acquire::Check-Date', 'true'],
}.freeze

describe 'baseline::apt' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:conf) { '/etc/apt/apt.conf.d/99-baseline' }

      it { is_expected.to compile.with_all_deps }

      APT_DIRECTORIES.each do |id, dir|
        it "#{id}: #{dir} is root:root 0755" do
          is_expected.to contain_file(dir).with(ensure: 'directory', owner: 'root', group: 'root', mode: '0755')
        end

        it "#{id}: does not manage the contents of #{dir}" do
          is_expected.to contain_file(dir).without_recurse.without_purge
        end
      end

      it { is_expected.to contain_file(conf).with(owner: 'root', group: 'root', mode: '0644') }

      APT_SETTINGS.each do |id, (key, value)|
        it "#{id}: sets #{key} to #{value}" do
          is_expected.to contain_file(conf).with_content(%r{^#{Regexp.escape(key)} "#{value}";$})
        end
      end
    end
  end
end
