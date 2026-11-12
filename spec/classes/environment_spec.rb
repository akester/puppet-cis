# frozen_string_literal: true

require 'spec_helper'

describe 'baseline::environment' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include baseline' }
      let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
      let(:tmout) { '/etc/profile.d/50-tmout.sh' }

      it { is_expected.to compile.with_all_deps }

      it 'hl-env-001: TMOUT is 900, readonly and exported' do
        is_expected.to contain_file(tmout)
          .with(owner: 'root', group: 'root', mode: '0644')
          .with_content(%r{^TMOUT=900\nreadonly TMOUT\nexport TMOUT\n})
      end

      it 'hl-env-001: no typeset, which dash lacks' do
        is_expected.to contain_file(tmout).without_content(%r{typeset})
      end

      ['/etc/profile', '/etc/bash.bashrc'].each do |path|
        it "hl-env-001: no other TMOUT in #{path}" do
          is_expected.to contain_file_line("#{path} TMOUT")
            .with(ensure: 'absent', path: path, match_for_absence: true, multiple: true,
                  match: '^\s*(export\s+|readonly\s+|typeset\s+\S+\s+)?TMOUT\b')
        end
      end

      it 'hl-env-002: profile.d sets umask 027' do
        is_expected.to contain_file('/etc/profile.d/60-default_umask.sh')
          .with(owner: 'root', group: 'root', mode: '0644')
          .with_content(%r{^umask 027$})
      end

      it 'hl-env-003: login.defs UMASK 027' do
        is_expected.to contain_file_line('login.defs UMASK')
          .with(path: '/etc/login.defs', line: 'UMASK 027', match: '^\s*#?\s*UMASK\s')
      end

      it 'hl-env-004: weaker umasks are commented out' do
        weak = '^\h*umask\h+(?!0?[02367]7\b)'
        files = '/etc/profile /etc/profile.d/*.sh'
        is_expected.to contain_exec('comment out weak umasks').with(
          command: "grep -PlsZi '#{weak}' #{files} | xargs -0 -r perl -i -pe 's/^(?=#{weak})/# /i'",
          onlyif: "grep -Pqsi '#{weak}' #{files}",
          provider: 'shell',
        )
      end

      context 'with tmout => 600 in Hiera' do
        let(:facts) { os_facts.merge(hiera_case: 'tmout_600') }

        it { is_expected.to contain_file(tmout).with_content(%r{^TMOUT=600$}) }
      end
    end
  end
end
