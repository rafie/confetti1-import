require 'rake/testtask'
require "bundler/gem_tasks"

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/units/*_test.rb', 'test/specs/*_spec.rb']
  t.verbose = true
end

desc "Run tests"
task :default => :test


desc "Build and install gem"
namespace :build do
  task :install  do
    puts `gem build confetti1-import.gemspec`
    puts `gem install confetti1-import-0.0.1.gem`
  end
end