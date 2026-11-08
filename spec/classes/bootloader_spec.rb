# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::bootloader' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-boot-001: grub.cfg is root:root 0600' do
        is_expected.to contain_file('/boot/grub/grub.cfg').with(owner: 'root', group: 'root', mode: '0600')
      end

      it 'hl-boot-001: does not create grub.cfg where it is missing' do
        is_expected.to contain_file('/boot/grub/grub.cfg').without_ensure
      end
    end
  end
end
