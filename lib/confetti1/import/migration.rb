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
	c.option '--gitdir DIR',String, 'Git repository Location'
	c.option '--viewname VIEWNAME',String, 'original clearcase view'
	c.action do |args, options|		
		
		gitRepoFolder = ENV['GITDIR'] if ENV['GITDIR']
		gitRepoFolder = options.gitdir if options.gitdir
		raise ("no git folder specified") if !gitRepoFolder
		viewname = ENV['VIEWNAME'] if ENV['VIEWNAME']
		viewname = options.viewname if options.viewname
		raise ("no view name specified") if !viewname
		
		repo = Confetti1::Import::GitRepo.create(gitRepoFolder, viewname)
		repo.add_ignore_list()
	end
end


command :version do |c|
	c.syntax = 'import version [options]'
	c.summary = ''
	c.description = ''
	c.example 'description', 'command example'
	c.option '-x VERSION', String, 'Specify a version eg:mcu-7.6.1/7.6.1.1.0'
	c.option '--gitdir DIR',String, 'Git repository Location'
	c.option '--viewname VIEWNAME',String, 'original clearcase view'

	c.action do |args, options|
		t1 = Time.now
		pversion = options.x
		pversion.gsub!('\\','/')
		gitRepoFolder = ENV['GITDIR'] if ENV['GITDIR']
		gitRepoFolder = options.gitdir if options.gitdir
		raise ("no git folder specified") if !gitRepoFolder
		viewName = ENV['VIEWNAME'] if ENV['VIEWNAME']
		viewName = options.viewname if options.viewname
		raise ("no view name specified") if !viewName		
		repo = Confetti1::Import.GitRepo(gitRepoFolder, viewName)
		cspec = Confetti1::Import.ConfigSpec(pversion) #mcu-8.3.2\8.3.2.1.1
		cspec.applyToView(viewName)
		cspec.migrate(repo)
		t2 = Time.now
		t3=t2-t1
		h=(t3/3600).to_i
		t3=t3-(h*3600)
		m=(t3/60).to_i
		t3=t3-(m*60)
		puts "migration duration : #{h} hour(s), #{m} minutes and #{t3} seconds"
	end
end

command :project do |c|
	c.syntax = 'import project [options]'
	c.summary = ''
	c.description = ''
	c.example 'description', 'command example'
	c.option '--proj PROJECT', String, 'Specify a project eg:mcu-7.6.1'
	c.option '--gitdir DIR',String, 'Git repository Location'
	c.option '--viewname VIEWNAME',String, 'original clearcase view'

	c.action do |args, options|
		t1 = Time.now
		proj = options.proj
		gitRepoFolder = ENV['GITDIR'] if ENV['GITDIR']
		gitRepoFolder = options.gitdir if options.gitdir
		raise ("no git folder specified") if !gitRepoFolder
		viewName = ENV['VIEWNAME'] if ENV['VIEWNAME']
		viewName = options.viewname if options.viewname
		raise ("no view name specified") if !viewName		
		p = Confetti1::Import.Project(proj)
		puts p.versions
		t2 = Time.now
		t3=t2-t1
		h=(t3/3600).to_i
		t3=t3-(h*3600)
		m=(t3/60).to_i
		t3=t3-(m*60)
		#puts "migration duration : #{h} hour(s), #{m} minutes and #{t3} seconds"
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
