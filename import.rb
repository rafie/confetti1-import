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

command :'import-version' do |c|
	c.option '--version VER'
	c.option '--branch BRA'
	c.option '--product PROD'
	c.action do |args, options|
	end
end

command :'import-product' do |c|
	c.option '--version VER'
	c.option '--branch BRA'
	c.option '--product PROD'
	c.action do |args, options|

		product = Product.new(options.product)
		ccase_view = ClearCase::View.new(Config.clearcase_view)
		ccase_view.configspec = product
		Version.	
		self.commit_version(File.join(ConfettiEnv.versions_path, options.version, 'configspec.txt'))
	end
end

command :scan do |c|
	c.action do |args, options|
	end
end


# import --version mcu-7.6.1/7.6.1.4.0
# import --branch mcu-7.6.1_int --version 7.6.1.2.0 --tag mcu_7.6.1.2.0
# import --product mcu-7.6.1 --from-tag mcu_7.5.1.10.8
