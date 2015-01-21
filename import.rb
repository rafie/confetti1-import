# $:.unshift(File.join(File.dirname(__FILE__), "lib"))

require_relative 'lib/confetti1/import'

reuqire 'commander/import'

Confetti1::Import.main(ARGV)

program :name, 'Confetti ClearCase-Git import'
program :version, '1.0.0'
 
command :init do |c|
	c.action do |args, options|
		ConfettiEnv.git_repozitories.each do |repo|
			git = Git.new(path: repo)
			git.init
			@gits << git
		end
	end
end

command :'build-versions' do |c|
	c.action do |args, options|
		self.build_versions
	end
end

command  do |c|
	c.action do |args, options|
	end
end

command :import do |c|
	c.option '--version VER'
	c.action do |args, options|
		raise ArgumentError.new("Path to version is empty") if arguments.empty?
		self.commit_version(File.join(ConfettiEnv.versions_path, options.version, 'configspec.txt'))
	end
end

command  do |c|
	c.action do |args, options|
	end
end

command  do |c|
	c.action do |args, options|
	end
end

command  do |c|
	c.action do |args, options|
	end
end

