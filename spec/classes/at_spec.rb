# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::at' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-at-001: /etc/at.allow lists only root' do
        is_expected.to contain_file('/etc/at.allow')
          .with(ensure: 'file', owner: 'root', group: 'daemon', mode: '0640', content: "root\n")
      end

      it 'fixes /etc/at.deny access only where it exists' do
        is_expected.to contain_file('/etc/at.deny').with(owner: 'root', group: 'daemon', mode: '0640').without_ensure
      end

      it { is_expected.not_to contain_package('at') }

      context 'with more users in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'at_allow_users') }

        it 'hl-at-001: lists them in /etc/at.allow' do
          is_expected.to contain_file('/etc/at.allow').with_content("root\nandrew\n")
        end
      end
    end
  end
end
