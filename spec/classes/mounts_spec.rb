# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::mounts' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

      def options(path)
        catalogue.resource('Mount', path)[:options].split(',')
      end

      def tmp_options
        options('/tmp')
      end

      it { is_expected.to compile.with_all_deps }

      it 'hl-mount-001: mounts /tmp as a tmpfs' do
        is_expected.to contain_mount('/tmp').with(ensure: 'mounted', device: 'tmpfs', fstype: 'tmpfs')
      end

      it 'hl-mount-001: limits /tmp to 1G by default' do
        expect(tmp_options).to include('size=1G')
      end

      it 'hl-mount-002: mounts /tmp nodev' do
        expect(tmp_options).to include('nodev')
      end

      it 'hl-mount-003: mounts /tmp nosuid' do
        expect(tmp_options).to include('nosuid')
      end

      it 'does not mount /tmp noexec (CIS 1.1.2.1.4 deviation)' do
        expect(tmp_options).not_to include('noexec')
      end

      it 'hl-mount-008: mounts /var/tmp as a tmpfs' do
        is_expected.to contain_mount('/var/tmp').with(ensure: 'mounted', device: 'tmpfs', fstype: 'tmpfs')
      end

      {
        'hl-mount-009' => 'nodev',
        'hl-mount-010' => 'nosuid',
        'hl-mount-011' => 'noexec',
      }.each do |id, option|
        it "#{id}: mounts /var/tmp #{option}" do
          expect(options('/var/tmp')).to include(option)
        end
      end

      it 'hl-mount-004: mounts /dev/shm as a tmpfs' do
        is_expected.to contain_mount('/dev/shm').with(ensure: 'mounted', device: 'tmpfs', fstype: 'tmpfs')
      end

      {
        'hl-mount-005' => 'nodev',
        'hl-mount-006' => 'nosuid',
        'hl-mount-007' => 'noexec',
      }.each do |id, option|
        it "#{id}: mounts /dev/shm #{option}" do
          expect(options('/dev/shm')).to include(option)
        end
      end

      context 'with tmp_size set in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'mounts_tmp_size') }

        it 'hl-mount-001: uses the configured /tmp size' do
          expect(tmp_options).to include('size=25%')
        end
      end
    end
  end
end
