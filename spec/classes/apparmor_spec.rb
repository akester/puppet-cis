# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::apparmor' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-apparmor-001: installs apparmor' do
        is_expected.to contain_package('apparmor').with_ensure('installed')
      end

      it 'hl-apparmor-002: installs apparmor-utils' do
        is_expected.to contain_package('apparmor-utils').with_ensure('installed')
      end
    end
  end
end
