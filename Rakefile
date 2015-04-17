require 'rubygems'
require 'bundler'
Bundler.require(:rake)
require 'rake/clean'

require 'puppet-lint/tasks/puppet-lint'
require 'rspec-system/rake_task'
require 'puppetlabs_spec_helper/rake_tasks'
# blacksmith does not support ruby 1.8.7 anymore
require 'puppet_blacksmith/rake_tasks' if ENV['RAKE_ENV'] != 'ci' && RUBY_VERSION.split('.')[0,3].join.to_i > 187

desc "Lint metadata.json file"
task :meta do
  sh "metadata-json-lint metadata.json"
end

PuppetLint.configuration.ignore_paths = ["spec/fixtures/modules/*/**.pp"]
PuppetLint.configuration.log_format = '%{path}:%{linenumber}:%{KIND}: %{message}'

task :librarian_spec_prep do
  sh 'librarian-puppet install --path=spec/fixtures/modules/'
end
task :spec_prep => :librarian_spec_prep
task :default => [:validate, :spec, :lint]
