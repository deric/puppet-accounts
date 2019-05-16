source "https://rubygems.org"

group :test do
  gem "puppet", ENV['PUPPET_VERSION'] || ['> 3.3.0','< 6.0']
  gem "rspec"
  gem 'rspec-puppet'
  gem "puppetlabs_spec_helper"
  gem 'rspec-puppet-facts'
  gem 'simplecov', '>= 0.11.0'
  gem 'simplecov-console'
  gem 'deep_merge'
  gem 'hiera'
  gem 'librarian-puppet' , '>=2.0'
  gem 'metadata-json-lint'
  gem 'rubocop'
  gem 'rake'
  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem "puppet-lint-unquoted_string-check"
  gem 'puppet-lint-resource_reference_syntax'
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem 'puppet-blacksmith', git: 'https://github.com/deric/puppet-blacksmith', branch: 'tag-order'
  gem "guard-rake"
end

group :system_tests do
  gem 'pry'
  gem 'beaker'
  gem 'beaker-rspec'
  gem 'beaker-docker'
  gem 'serverspec'
  gem 'beaker-hostgenerator'
  gem 'beaker-puppet_install_helper'
  gem 'master_manipulator'
end
