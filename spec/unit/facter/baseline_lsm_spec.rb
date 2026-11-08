# frozen_string_literal: true

require 'spec_helper'

describe 'baseline_lsm' do
  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
    allow(File).to receive(:readable?).and_call_original
    allow(File).to receive(:read).and_call_original
  end

  after { Facter.clear }

  it 'lists the active LSMs in order' do
    allow(File).to receive(:readable?).with('/sys/kernel/security/lsm').and_return(true)
    allow(File).to receive(:read).with('/sys/kernel/security/lsm').and_return("lockdown,capability,landlock,yama,apparmor\n")
    expect(Facter.fact(:baseline_lsm).value).to eq(%w[lockdown capability landlock yama apparmor])
  end

  it 'is unset when securityfs is not mounted' do
    allow(File).to receive(:readable?).with('/sys/kernel/security/lsm').and_return(false)
    expect(Facter.fact(:baseline_lsm).value).to be_nil
  end
end
