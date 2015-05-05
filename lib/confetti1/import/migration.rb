require 'commander/import'
require 'json'
require_relative 'configspec.rb'

module Confetti1
module Import


program :name, "import"
program :version, '1.0'
program :description, 'migration'

	command :create do |c|
		conf=File.read(File.expand_path(File.join("..", "..", "..","..","migrationparams.json"), __FILE__))
		my_hash = JSON.parse(conf)
		gitRepoFolder = my_hash["gitRepoFolder"]
		viewName = my_hash["viewName"]
		versionsForestLocation = my_hash["versionsForestLocation"]
		repo = GitRepo.create(gitRepoFolder,viewName)	
		repo.add_ignore_list()
	end
	
	
	command :version do |c|		
		c.option '-v', '--VER VERSION', String, 'Specify a version eg:mcu-7.6.1/7.6.1.1.0' # Option aliasing
		conf=File.read(File.expand_path(File.join("..", "..", "..","..","migrationparams.json"), __FILE__))
		my_hash = JSON.parse(conf)
		gitRepoFolder = my_hash["gitRepoFolder"]
		viewName = my_hash["viewName"]
		versionsForestLocation = my_hash["versionsForestLocation"]
		cspec = ConfigSpec.is("#{versionsForestLocation}/#{options.VER}/configspec.txt")
		cspec.applyToView("viewName")
		cspec.migrate(repo)
	end #command
end #Import
end #Confetti1