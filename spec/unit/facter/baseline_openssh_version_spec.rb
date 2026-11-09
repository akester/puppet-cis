# frozen_string_literal: true

require 'spec_helper'

describe 'baseline_openssh_version' do
  let(:command) { "dpkg-query -W -f='${Version}' openssh-server 2>/dev/null" }

  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
  end

  after { Facter.clear }

  it 'strips the epoch and Debian revision' do
    allow(Facter::Core::Execution).to receive(:execute).with(command, on_fail: nil).and_return('1:10.0p1-7+deb13u4')
    expect(Facter.fact(:baseline_openssh_version).value).to eq('10.0')
  end

  it 'reads an Ubuntu version' do
    allow(Facter::Core::Execution).to receive(:execute).with(command, on_fail: nil).and_return('1:9.6p1-3ubuntu13.5')
    expect(Facter.fact(:baseline_openssh_version).value).to eq('9.6')
  end

  it 'is unset when openssh-server is not installed' do
    allow(Facter::Core::Execution).to receive(:execute).with(command, on_fail: nil).and_return(nil)
    expect(Facter.fact(:baseline_openssh_version).value).to be_nil
  end
end
