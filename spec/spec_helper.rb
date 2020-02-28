# frozen_string_literal: true

require 'puppet'
require 'rspec'
require 'rspec/its'
require 'rspec-puppet-facts'

include RspecPuppetFacts
Puppet::Util::Log.level = :debug
Puppet::Util::Log.newdestination(:console)

# migrate from mocha to rspec-mocks
# see https://github.com/puppetlabs/puppetlabs_spec_helper#mock_with
RSpec.configure do |c|
  c.mock_with :rspec
end
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
RSpec.configure do |c|
  #c.treat_symbols_as_metadata_keys_with_true_values = true
  c.include PuppetlabsSpec::Files
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.template_dir = File.join(fixture_path, 'templates')

  c.before(:each) do
    # Stub assert_private function from stdlib to not fail within this test
    Puppet::Parser::Functions.newfunction(:assert_private) { |_| }
  end
end

at_exit { RSpec::Puppet::Coverage.report! }
