require 'puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

include RspecPuppetFacts
Puppet::Util::Log.level = :debug
Puppet::Util::Log.newdestination(:console)

RSpec.configure do |c|
  #c.treat_symbols_as_metadata_keys_with_true_values = true
  c.include PuppetlabsSpec::Files
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
end

at_exit { RSpec::Puppet::Coverage.report! }