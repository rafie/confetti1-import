require 'commander/import'
require 'json'
require_relative 'configspec.rb'
#require 'byebug'

program :name, "import"
program :version, "1.1"
program :description, 'migration'

command :create do |c|
	
	c.syntax = 'import create'
	c.summary = 'Create a new project version'
	c.description = ''
	c.example 'description', 'command example'
	c.option '--some-switch', 'Some switch that does something'

	c.action do |args, options|
		
		conf=File.read(File.expand_path(File.join("..", "..", "..","..","config","migrationparams.json"), __FILE__))
		my_hash = JSON.parse(conf)
		gitRepoFolder = my_hash["gitRepoFolder"]
		viewName = my_hash["viewName"]
		versionsForestLocation = my_hash["versionsForestLocation"]
		repo = Confetti1::Import::GitRepo.create(gitRepoFolder, viewName)
		repo.add_ignore_list()
	end
end


command :version do |c|
	c.syntax = 'import version [options]'
	c.summary = ''
	c.description = ''
	c.example 'description', 'command example'
	c.option '-x VERSION', String, 'Specify a version eg:mcu-7.6.1/7.6.1.1.0'

	c.action do |args, options|
		pversion = options.x

		conf=File.read(File.expand_path(File.join("..", "..", "..","..","config","migrationparams.json"), __FILE__))
		my_hash = JSON.parse(conf)
		gitRepoFolder = my_hash["gitRepoFolder"]
		viewName = my_hash["viewName"]
		versionsForestLocation = my_hash["versionsForestLocation"]

		repo = Confetti1::Import.GitRepo(gitRepoFolder, viewName)
		
		cspec = Confetti1::Import.ConfigSpec("#{versionsForestLocation}/#{pversion}/configspec.txt") #mcu-8.3.2\8.3.2.1.1
		cspec.applyToView(viewName)
		cspec.migrate(repo)
	end
end

# end #Import
# end #Confetti1

# set IMPORT_GIT=d:\git
# set IMPORT_VIEW=m:\view1
# import create --git-dir d:\git

# import version --version mcu-7.6.1/7.6.1.1.0 --view m:\view1 --git-dir d:\git

# set IMPORT_GIT=d:\git
# set IMPORT_VIEW=m:\view1
# import version --version mcu-7.6.1/7.6.1.1.0
# import version --version mcu-7.6.1/7.6.1.2.0
# import version --version mcu-7.6.1/7.6.1.3.0

# import project --name mcu-7.6.1
