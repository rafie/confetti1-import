require 'commander/import'
require 'json'
require_relative 'migration_classes.rb'

program :name, "import"
program :version, "1.1"
program :description, 'migration'

#----------------------------------------------------------------------------------------------

command :create do |c|	
	c.syntax = 'import create'
	c.summary = 'Create a new project version'
	c.description = ''
	c.example 'description', 'command example'
	c.option '--gitdir DIR',String, 'Git repository Location'
	c.option '--viewname VIEWNAME',String, 'original clearcase view'
	c.action do |args, options|			
		
		repo = Confetti1::Import::GitRepo.create(options.gitdir, options.viewname)
		
	end
end

#----------------------------------------------------------------------------------------------

command :version do |c|
	c.syntax = 'import version [options]'
	c.summary = ''
	c.description = ''
	c.example 'description', 'command example'
	c.option '--versionname VERSION', String, 'Specify a version eg:mcu-7.6.1/7.6.1.1.0'
	c.option '--gitdir DIR',String, 'Git repository Location'
	c.option '--viewname VIEWNAME',String, 'original clearcase view'

	c.action do |args, options|		
		repo = Confetti1::Import::GitRepo(options.gitdir, options.viewname)	
		view = Confetti1::Import.View(options.viewname)
		version = Confetti1::Import.Version(options.versionname) #mcu-8.3.2\8.3.2.1.1
		version.migrate(repo,view)
	end
end

#----------------------------------------------------------------------------------------------

command :project do |c|
	c.syntax = 'import project [options]'
	c.summary = ''
	c.description = ''
	c.example 'description', 'command example'
	c.option '--proj PROJECT', String, 'Specify a project eg:mcu-7.6.1'
	c.option '--gitdir DIR',String, 'Git repository Location'
	c.option '--viewname VIEWNAME',String, 'original clearcase view'

	c.action do |args, options|
		
		p = Confetti1::Import.Project(options.proj)
		repo = Confetti1::Import::GitRepo(options.gitdir, options.viewname)	
		p.migrate(repo,viewName)
		
	end
end


command :all do |c|
	c.syntax = 'import all [options]'
	c.summary = ''
	c.description = ''
	c.example 'description', 'command example'
	c.option '--gitdir DIR',String, 'Git repository Location'
	c.option '--viewname VIEWNAME',String, 'original clearcase view'

	c.action do |args, options|
		repo = Confetti1::Import::GitRepo(options.gitdir, options.viewname)	
		
		
		view = Confetti1::Import.View(options.viewname)
		repo = Confetti1::Import::GitRepo(options.gitdir, options.viewname)
		view.migrate(repo)
		
	end
end

