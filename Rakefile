require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

RSpec::Core::RakeTask.new('spec:without_ios') do |t|
  t.rspec_opts = '--tag ~requires_ios'
end

desc 'Run tests on Travis'
task :ci => 'spec:without_ios'
