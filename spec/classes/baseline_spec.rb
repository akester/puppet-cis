# frozen_string_literal: true

require 'spec_helper'

describe 'baseline' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('baseline::sysctl') }
      it { is_expected.to contain_class('baseline::kmod') }
      it { is_expected.to contain_class('baseline::mounts') }
      it { is_expected.to contain_class('baseline::apt') }
      it { is_expected.to contain_class('baseline::apparmor') }
      it { is_expected.to contain_class('baseline::bootloader') }
      it { is_expected.to contain_class('baseline::process') }
      it { is_expected.to contain_class('baseline::banners') }

      context 'with manage_sysctl => false' do
        let(:params) { { manage_sysctl: false } }

        it { is_expected.not_to contain_class('baseline::sysctl') }
      end

      context 'with manage_kmod => false' do
        let(:params) { { manage_kmod: false } }

        it { is_expected.not_to contain_class('baseline::kmod') }
      end

      context 'with manage_mounts => false' do
        let(:params) { { manage_mounts: false } }

        it { is_expected.not_to contain_class('baseline::mounts') }
      end

      context 'with manage_apt => false' do
        let(:params) { { manage_apt: false } }

        it { is_expected.not_to contain_class('baseline::apt') }
      end

      context 'with manage_apparmor => false' do
        let(:params) { { manage_apparmor: false } }

        it { is_expected.not_to contain_class('baseline::apparmor') }
      end

      context 'with manage_bootloader => false' do
        let(:params) { { manage_bootloader: false } }

        it { is_expected.not_to contain_class('baseline::bootloader') }
      end

      context 'with manage_process => false' do
        let(:params) { { manage_process: false } }

        it { is_expected.not_to contain_class('baseline::process') }
      end

      context 'with manage_banners => false' do
        let(:params) { { manage_banners: false } }

        it { is_expected.not_to contain_class('baseline::banners') }
      end
    end
  end
end
