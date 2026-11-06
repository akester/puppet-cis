# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :test do
  gem 'voxpupuli-test', '~> 15.0', require: false
  gem 'puppet_metadata', '~> 6.4', require: false
end

gem 'rake', require: false

# Test against OpenVox (not Perforce Puppet). CI pins the major via OPENVOX_GEM_VERSION.
gem 'openvox', ENV.fetch('OPENVOX_GEM_VERSION', ['>= 8', '< 10']), require: false, groups: [:test]
