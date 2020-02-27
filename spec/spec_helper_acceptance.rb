# frozen_string_literal: true

require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

UNSUPPORTED_PLATFORMS = ['windows','AIX','Solaris'].freeze

HIERA_PATH = '/etc/puppetlabs/code/environments/production'

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation
  hiera_config = '/etc/puppetlabs/puppet/hiera.yaml'

  # Configure all nodes in nodeset
  c.before :suite do
    # Install modules and dependencies from spec/fixtures/modules

    hosts.each do |host|
      if ['RedHat'].include?(fact('osfamily'))
        on host, 'yum install -y tar'
      end
      #binding.pry
      on host, "mkdir -p /etc/puppetlabs/puppet /etc/puppet/modules", { :acceptable_exit_codes => [0] }
      on host, "mkdir -p #{HIERA_PATH}", { :acceptable_exit_codes => [0] }
      scp_to host, File.expand_path('./spec/acceptance/hiera.yaml'), hiera_config
      # compatibility with puppet 3.x
      on host, "ln -s #{hiera_config} /etc/puppet/hiera.yaml", { :acceptable_exit_codes => [0] }
      on host, "ln -s #{HIERA_PATH}/hieradata /etc/puppetlabs/puppet/hieradata", { :acceptable_exit_codes => [0] }
      scp_to host, File.expand_path('./spec/acceptance/hieradata'), HIERA_PATH
      # assume puppet is on $PATH
      on host, "puppet --version"

      install_module_dependencies
      install_module_on(host)

      on host, "puppet module list"
    end
  end
end
