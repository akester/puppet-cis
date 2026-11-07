# frozen_string_literal: true

require 'spec_helper'

# ID => module name
KMOD_DENIED = {
  'hl-kmod-001' => 'cramfs',
  'hl-kmod-002' => 'freevxfs',
  'hl-kmod-003' => 'hfs',
  'hl-kmod-004' => 'hfsplus',
  'hl-kmod-005' => 'jffs2',
  'hl-kmod-006' => 'firewire-core',
  'hl-kmod-007' => 'usb-storage',
  'hl-kmod-008' => 'atm',
  'hl-kmod-009' => 'can',
  'hl-kmod-010' => 'dccp',
  'hl-kmod-011' => 'rds',
  'hl-kmod-012' => 'sctp',
  'hl-kmod-013' => 'tipc',
}.freeze

# hl-kmod-014 (CIS 1.1.1.11): unused filesystem modules.
KMOD_UNUSED_FS = %w[
  9p adfs affs bcachefs befs bfs btrfs cachefiles ceph cifs coda cuse dlm ecryptfs efs erofs exfat
  f2fs gfs2 hpfs jfs kafs ksmbd minix msdos nfsd nfsv2 nilfs2 ntfs3 ocfs2 ocfs2_stack_o2cb
  ocfs2_stack_user ocfs2_stackglue omfs orangefs pstore_blk pstore_zone qnx4 qnx6 quota_tree
  quota_v1 quota_v2 ramoops reiserfs romfs sysv ubifs udf ufs vboxsf xfs zonefs
].freeze

# Must never be denied.
KMOD_KEPT = %w[ext4 jbd2 fat vfat isofs efivarfs autofs4 configfs overlay squashfs nfs nfsv3 nfsv4 lockd grace nfs_acl netfs].freeze

describe 'baseline::kmod' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      # FacterDB's Debian 13 facts include a vboxsf mount; use a plain host instead.
      let(:plain_mounts) { { '/' => { 'filesystem' => 'ext4' }, '/boot/efi' => { 'filesystem' => 'vfat' } } }
      let(:facts) { os_facts.merge(mountpoints: plain_mounts) }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
      let(:target) { '/etc/modprobe.d/60-baseline.conf' }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file(target).with(owner: 'root', group: 'root', mode: '0644') }

      KMOD_DENIED.each do |id, mod|
        it "#{id}: prevents loading #{mod}" do
          is_expected.to contain_file(target)
            .with_content(%r{^install #{Regexp.escape(mod)} /bin/false$})
            .with_content(%r{^blacklist #{Regexp.escape(mod)}$})
        end
      end

      it 'hl-kmod-014: prevents loading every unused filesystem module' do
        KMOD_UNUSED_FS.each do |mod|
          is_expected.to contain_file(target).with_content(%r{^install #{mod} /bin/false$\nblacklist #{mod}$})
        end
      end

      it 'hl-kmod-014: leaves filesystems the fleet uses loadable' do
        KMOD_KEPT.each do |mod|
          is_expected.to contain_file(target).without_content(%r{ #{mod}( |$)})
        end
      end

      context 'with xfs and an ISO mounted' do
        let(:facts) do
          os_facts.merge(mountpoints: {
                           '/' => { 'filesystem' => 'xfs' },
                           '/mnt/cd' => { 'filesystem' => 'iso9660' },
                         })
        end

        it 'hl-kmod-014: does not deny a mounted filesystem' do
          is_expected.to contain_file(target).without_content(%r{ xfs( |$)})
          is_expected.to contain_file(target).with_content(%r{^install btrfs /bin/false$})
        end
      end

      context 'with usb-storage allowed in Hiera' do
        let(:facts) { os_facts.merge(mountpoints: plain_mounts, hiera_case: 'kmod_allow_usb') }

        it 'hl-kmod-007: leaves usb-storage loadable' do
          is_expected.to contain_file(target).without_content(%r{usb-storage})
        end

        it 'hl-kmod-006: still blocks the other modules' do
          is_expected.to contain_file(target).with_content(%r{^install firewire-core /bin/false$})
        end
      end

      context 'with nfsd allowed in Hiera (NFS server)' do
        let(:facts) { os_facts.merge(mountpoints: plain_mounts, hiera_case: 'kmod_allow_nfsd') }

        it 'hl-kmod-014: leaves nfsd loadable' do
          is_expected.to contain_file(target).without_content(%r{ nfsd( |$)})
        end
      end

      context 'with an unknown module in allow' do
        let(:facts) { os_facts.merge(mountpoints: plain_mounts, hiera_case: 'kmod_allow_typo') }

        it { is_expected.to compile.and_raise_error(%r{aren't in the list: usb_storage}) }
      end
    end
  end
end
