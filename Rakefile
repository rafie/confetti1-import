require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

desc "Build and install gem"
task :install do
  require 'confetti1/import' 
  system "gem uninstall confetti1-import"
  raise 'Build failed!' unless system('rake test --trace')
  `gem build confetti1-import.gemspec`
  `gem install confetti1-import-#{Confetti1::Import.version}.gem`
end