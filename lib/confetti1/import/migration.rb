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
		
		gitRepoFolder = ENV['GITDIR'] if ENV['GITDIR']
		gitRepoFolder = options.gitdir if options.gitdir
		
		viewname = ENV['VIEWNAME'] if ENV['VIEWNAME']
		viewname = options.viewname if options.viewname		
		
		repo = Confetti1::Import::GitRepo.create(gitRepoFolder, viewname)
		
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
		
		pversion = options.versionname
		pversion.gsub!('\\','/')
		
		gitRepoFolder = ENV['GITDIR'] if ENV['GITDIR']
		gitRepoFolder = options.gitdir if options.gitdir		
		view_name = ENV['VIEWNAME'] if ENV['VIEWNAME']
		view_name = options.viewname if options.viewname				
		repo = Confetti1::Import.GitRepo(gitRepoFolder, view_name)		
		view = Confetti1::Import.View(view_name)
		version = Confetti1::Import.Version(pversion) #mcu-8.3.2\8.3.2.1.1
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
		
		proj = options.proj
		gitRepoFolder = ENV['GITDIR'] if ENV['GITDIR']
		gitRepoFolder = options.gitdir if options.gitdir		
		viewName = ENV['VIEWNAME'] if ENV['VIEWNAME']
		viewName = options.viewname if options.viewname
		p = Confetti1::Import.Project(proj)
		repo = Confetti1::Import.GitRepo(gitRepoFolder, viewName)
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
		t1 = Time.now
		gitRepoFolder = ENV['GITDIR'] if ENV['GITDIR']
		gitRepoFolder = options.gitdir if options.gitdir
		viewName = ENV['VIEWNAME'] if ENV['VIEWNAME']
		viewName = options.viewname if options.viewname
		repo = Confetti1::Import.GitRepo(gitRepoFolder, viewName)		
		
		import_order = File.expand_path(File.join("..", "..", "..","..","importwf.txt"), __FILE__)
		text=File.open(import_order).read
		text.each_line do |line|
			proj=line.split(";")[0]
			origin=line.split(";"){1}
			p = Confetti1::Import.Project(proj)
			p.migrate(repo,viewName,origin)
		end
		
		
		t2 = Time.now
		t=t2-t1
		t=vt2-vt1
		mm, ss = t.divmod(60)           
		hh, mm = mm.divmod(60)          
		puts "Project #{proj} import OK; duration: %d:%d:%d seconds" % [hh, mm, ss]
		Log.write_log("Complete view import OK; duration: %d:%d:%d seconds" % [hh, mm, ss])
	end
end

