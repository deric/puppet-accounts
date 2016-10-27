source "https://rubygems.org"

group :test do
  gem "rake"
  gem "puppet", ENV['PUPPET_VERSION'] || ['> 3.3.0','< 5.0']
  gem "rspec"
  gem 'rspec-puppet'
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem 'rspec-puppet-facts'
  gem 'simplecov', '>= 0.11.0'
  gem 'simplecov-console'
  gem 'deep_merge'
  gem 'hiera'
  gem 'librarian-puppet' , '>=2.0'
  # newer versions require ruby 2.2
  if RUBY_VERSION < "2.2.0"
    gem 'listen', '~> 3.0.0'
  end
  if RUBY_VERSION < "2.0.0"
    gem 'json', '< 2.0' # newer versions requires at least ruby 2.0
    gem 'json_pure', '< 2.0.0'
    gem 'fog-google', '< 0.1.1'
    gem 'google-api-client', '< 0.9'
    gem 'rubocop','~> 0.33.0'
  else
    gem 'rubocop'
  end
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
  gem "puppet-blacksmith"
  gem "guard-rake"
end

group :system_tests do
  gem 'pry'
  # beaker-rspec will require beaker gem
  if RUBY_VERSION >= '2.2.5'
    gem 'beaker'
  else
    gem 'beaker', '< 3'
  end
  gem 'beaker-rspec'
  gem 'serverspec'
  gem 'beaker-hostgenerator'
  gem 'beaker-puppet_install_helper'
  gem 'master_manipulator'
end
