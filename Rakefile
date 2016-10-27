require 'rubygems'
require 'bundler/setup'

require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet/version'
require 'puppet/vendor/semantic/lib/semantic' unless Puppet.version.to_f < 3.6
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'metadata-json-lint/rake_task'

# blacksmith does not support ruby 1.8.7 anymore
if ENV['RAKE_ENV'] != 'ci' and RUBY_VERSION >= "1.8.7"
  require 'puppet_blacksmith/rake_tasks'
end

desc "Lint metadata.json file"
task :meta do
  sh "metadata-json-lint metadata.json"
end

exclude_paths = [
  "bundle/**/*",
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
]

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = ["spec/**/*.pp", "vendor/**/*.pp", "pkg/**/*.pp"]
  config.log_format = '%{path}:%{linenumber}:%{KIND}: %{message}'
end

# use librarian-puppet to manage fixtures instead of .fixtures.yml
# offers more possibilities like explicit version management, forge downloads,...
task :librarian_spec_prep do
  sh 'librarian-puppet install --path=spec/fixtures/modules/'
end
task :spec_prep => :librarian_spec_prep


PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
end

PuppetSyntax.exclude_paths = exclude_paths

desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance) do |t|
  # just `spec/acceptance` caused runnin all specs
  t.pattern = 'spec/acceptance/*_spec.rb'
end

desc "Populate CONTRIBUTORS file"
task :contributors do
  system("git log --format='%aN' | sort -u > CONTRIBUTORS")
end
