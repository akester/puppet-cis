# frozen_string_literal: true

require 'spec_helper'

describe 'baseline' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('baseline::sysctl') }

      context 'with manage_sysctl => false' do
        let(:params) { { manage_sysctl: false } }

        it { is_expected.not_to contain_class('baseline::sysctl') }
      end
    end
  end
end
