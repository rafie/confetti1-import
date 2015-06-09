require 'yaml'
require 'Bento'
require 'fileutils'
require 'logger'

module Confetti1
module Import

#----------------------------------------------------------------------------------------------
class Version
	include Bento::Class

	constructors :is
	members :version_name, :cspecfile, :cspec, :tag
	
	def is(name)
	@version_name=name.gsub('\\','/')
	@tag=@version_name.split("/")[-2]
	
	endoftag=@version_name.split("/").last.split(".")[-2, 2].join(".")
	
	@tag << endoftag
	@cspecfile=File.expand_path(File.join("..", "..", "..","..","versions",name,"configspec.txt"), __FILE__)
	@cspec=ConfigSpec.is(@cspecfile)
	end
	
	def cspecfile
		@cspecfile
	end
	
	def configspec
		@cspec
	end
	
	def migrate(repo,view)
		
		view.configspec=@cspec
		ignore = File.read(File.join(repo.location,".git", "info", "exclude"))
		chrono = Timer.go
		@cspec.vobs.each do |vob|	
			unless ignore.include? vob	
				vobname=vob
				vobname[0]="/"
				print "Adding VOB #{vob}..."
				Log.write_log("Adding VOB #{vob}...")
				repo.add("m:/#{view.view_name}#{vob}")
				puts "VOB #{vob} added"
				Log.write_log("VOB #{vob} added")
			else
				puts "VOB #{vob} skipped"
				Log.write_log("VOB #{vob} skipped")
			end
		end
		puts "committing version #{@version_name}..."
		Log.write_log("committing version #{@version_name}...")
		repo.commit("migrated from clearcase",@tag)
		chrono.stop
		        
		puts "Version #{@version_name} import OK in #{chrono.to_s}"
		Log.write_log("Version #{@version_name} import OK in #{chrono.to_s}"
	end
	
end

#----------------------------------------------------------------------------------------------

class View
	include Bento::Class

	constructors :is
	members :view_name, :configspec
	
	def is(name)
		@view_name=ENV['VIEWNAME'] if name.nil?
		@view_name=name
		Log.error_log ("no view name specified") if @view_name.nil?
	end
	
	def view_name
		@view_name
	end
	
	def configspec=(configspec)
		@configspec = configspec
		@configspec.vobs.each do |vob|
			unless File.directory?("m:/#{@view_name}#{vob}")
				puts "VOB #{vob} must be mounted...please wait..."
				Log.write_log("VOB #{vob} must be mounted...please wait...")
				cmd = System.command("cleartool mount #{vob}")
				unless cmd.ok?
					Log.error_log("Mounting error, import failed!" )					
				end				
				puts "VOB #{vob} mounted"
				Log.write_log("VOB #{vob} mounted")
			end
		end
			cmd = System.command("cleartool setcs -tag #{@view_name} #{@configspec.cspecfile}")
	end
	
	def migrate(repo)
		chrono=Timer.go
		
		import_order = File.expand_path("../../../../importwf.txt", __FILE__)
		text=File.open(import_order).read
		text.each_line do |proj|
			origin = File.read(File.expand_path("../../../../versions/#{proj}/origin", __FILE__))			
			p = Confetti1::Import.Project(proj)
			p.migrate(repo,@view_name,origin)
		end
		
		chrono.stop        
		puts "view import OK in #{chrono.to_s}"
		Log.write_log("Complete view import OK in #{chrono.to_s}")
	end

end

#----------------------------------------------------------------------------------------------

class ConfigSpec
	include Bento::Class

	constructors :is	
	members :cspecfile, :vobs
	
	def is(cspecfile)
		@cspecfile = cspecfile
		cspec_parse
	end
	
	def vobs
		@vobs
	end
	
	def cspecfile
		@cspecfile
	end
	
	def cspec_parse
		@vobs = []
		IO.readlines(@cspecfile).each do |line|
			line.gsub!('\\', '/')
			next if ! line =~ /element\s+\/([^\/]+)\/...\s+(\S+)/ # element /vob/... label
			vob = $1
			label = $2
			@vobs << "\\#{vob}"
		end
	end
end

#----------------------------------------------------------------------------------------------
	
class GitRepo
	include Bento::Class

	constructors :is, :create
	members :repoLocation

	def is(repoLocation, viewName)
		repoLocation=ENV['GITDIR'] if repoLocation.nil?
		viewName=ENV['VIEWNAME'] if viewName.nil?
		Log.error_log ("no git folder specified") if repoLocation.nil?
		Log.error_log ("no view name specified") if viewName.nil?
		@repoLocation = repoLocation

	end
	
	def location
		@repoLocation
	end
	
	def create(repoLocation, viewName)
		is(repoLocation, viewName)
		system("git --git-dir=#{repoLocation}/.git --work-tree=m:/#{viewName} init")
		system("git commit --allow-empty -m \"initial commit\"")
		add_ignore_list()
	end
	
	def add(dir)
		cmd = System.command("git --git-dir=#{@repoLocation}/.git add #{dir}")
		
		unless cmd.ok?
				System.command("git --git-dir=#{@repoLocation}/.git reset")
				Log.error_log("git add #{dir} failed. Import cancelled and rolledback to last commit." )
		end
	end
	
	def commit(message, tag)
		cmd = System.command("git --git-dir=#{@repoLocation}/.git commit -m \"#{message}\"")		
		unless cmd.ok?
		puts "commit failed...rollback running..."
		Log.write_log("commit failed...rollback running...")
			System.command("git --git-dir=#{@repoLocation}/.git reset")
			Log.error_log("Commit error, import cancelled and rolledback to last commit" )
		end
		System.command("git --git-dir=#{@repoLocation}/.git tag #{tag}")
	end
	
	def add_ignore_list
		file_path = File.expand_path("../../../../exclude", __FILE__)
		destination_folder = "#{@repoLocation}/.git/info/"
		FileUtils.cp_r(file_path, destination_folder, :remove_destination => true)
	end
	
end #GitRepo

#----------------------------------------------------------------------------------------------

class Project
	include Bento::Class
	constructors :is
	members :name, :path, :arr_ver

	def is(name)
		@name = name
		@path=File.expand_path(File.join("..", "..", "..","versions",@name))
		Dir.chdir(@path) do
			@arr_ver=Dir["*"].reject{|o| not File.directory?(o)}
		end		
		@arr_ver=@arr_ver.map {|x| x.split('.').map{|y| y.to_i}}.sort.map {|x| x.join('.')}
	end
	
	def versions		
		@arr_ver
	end
	
	def migrate(repo,view_name,origin=nil)
		puts ("will execute git --git-dir=#{repo.location}/.git branch #{@name} #{origin}" )
		Log.write_log("will execute git --git-dir=#{repo.location}/.git branch #{@name} #{origin}")
		system("git --git-dir=#{repo.location}/.git branch #{@name}")
		puts ("will execute git --git-dir=#{repo.location}/.git symbolic-ref HEAD refs/heads/#{@name}")
		Log.write_log("will execute git --git-dir=#{repo.location}/.git symbolic-ref HEAD refs/heads/#{@name}")
		system("git --git-dir=#{repo.location}/.git symbolic-ref HEAD refs/heads/#{@name}")
		chrono = Timer.go
		versions.each do |ver|			
			pvers = Version.is("#{@name}/#{ver}") #mcu-8.3.2\8.3.2.1.1			
			pvers.migrate(repo,View.is(view_name))
		end
		
		# TODO: implement Timer
		chrono.stop
		puts "Project #{@name} import OK in #{chrono.to_s}"
		Log.write_log("Project #{@name} import OK in #{chrono.to_s}")
	end
	
end  #Projectf

#----------------------------------------------------------------------------------------------

class Log
	@@log = nil
	def self.write_log(message)
		# TODO: c:/temp is not robust. Let's use Ruby's Logger class
		logfile=File.expand_path("../../../log/logfile.log", __FILE__)
		logger = Logger.new(logfile)
		logger.info(message) 
		logger.close
	end
	def self.error_log(message)
		errfile=File.expand_path("../../../log/errfile.log", __FILE__)
		begin
			raise message 
		rescue Exception => e		
			logger = Logger.new(errfile)
			logger.error(e.message) 
			logger.error(e.backtrace.join("\n"))	
			logger.close	  
		ensure
		  puts "error, see #{errfile} for details"
		  exit
		end
	end
end

#----------------------------------------------------------------------------------------------
class Timer
	include Bento::Class
	constructors :go
	members :start, :end
	def go
		@start=Time.now
	end
	def stop
		@end=Time.now
		@end-@start
	end
	def to_s
		#Time.at(@end-@start).gmtime.strftime("%H:%M:%S.%L")
		mm, ss = (@end-@start).divmod(60)           
		hh, mm = mm.divmod(60)           
		dd, hh = hh.divmod(24)  
		str="%d : %d : %d" % [hh, mm, ss]
		str = "#{dd} days " + str if dd>0
		str		
	end
end
#----------------------------------------------------------------------------------------------
end # Import
end # Confetti1
