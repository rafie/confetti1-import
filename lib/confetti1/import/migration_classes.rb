require 'yaml'
require 'Bento'
require 'fileutils'

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
		vt1 = Time.now
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
		vt2 = Time.now
		# TODO: something like Time.at(vt2-vt1).gmtime.strftime("%H:%M:%S.%L")
		t=vt2-vt1
		mm, ss = t.divmod(60)           
		hh, mm = mm.divmod(60)          
		puts "Version #{@version_name} import OK; duration: %d:%d:%d seconds" % [hh, mm, ss]
		Log.write_log("Version #{@version_name} import OK; duration: %d:%d:%d seconds" % [hh, mm, ss])
	end
	
end

#----------------------------------------------------------------------------------------------

class View
	include Bento::Class

	constructors :is
	members :view_name, :configspec
	
	def is(name)
		@view_name=name
	end
	
	def view_name
		@view_name
	end
	
	def configspec=(repo)
		@configspec = repo
		@configspec.vobs.each do |vob|
				unless File.directory?("m:/#{@view_name}#{vob}")
					vn=vob
					vn[0]="\\"
					puts "VOB #{vn} must be mounted...please wait..."
					Log.write_log("VOB #{vn} must be mounted...please wait...")
					cmd = System.command("cleartool mount #{vn}")
					unless cmd.ok?
						Log.error_log("Mounting error, import failed!" )					
					end				
					puts "VOB #{vn} mounted"
					Log.write_log("VOB #{vn} mounted")
				end
		end
			cmd = System.command("cleartool setcs -tag #{@view_name} #{@configspec.cspecfile}")
	end

end

#----------------------------------------------------------------------------------------------

class ConfigSpec
	include Bento::Class

	constructors :is	
	members :cspecfile, :vobs
	
	def is(cspecfile)
		@cspecfile=cspecfile		
		cspec_parse()		
	end
	
	def vobs
		@vobs
	end
	
	def cspecfile
		@cspecfile
	end
	
	def cspec_parse
		out = IO.readlines(@cspecfile)
		out.reject! { |c| c[0,7]!="element" }
		out.shift
		@vobs = Array.new(out.length)		
		out.each_with_index {|val, index| @vobs[index]=val.squeeze(" ").split(" ")[1].chomp('...').chop }
	end
end

#----------------------------------------------------------------------------------------------
	
class GitRepo
	include Bento::Class

	constructors :is, :create
	members :repoLocation

	def is(repoLocation, viewName)
		Log.error_log ("no git folder specified") if !repoLocation
		Log.error_log ("no view name specified") if !viewName
		@repoLocation = repoLocation

	end
	
	def location
		@repoLocation
	end
	
	def create(repoLocation, viewName)
		Log.error_log("no git folder specified") if !repoLocation		
		Log.error_log ("no view name specified") if !viewName
		@repoLocation = repoLocation
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
		file_path = File.expand_path(File.join("..", "..", "..","..","exclude"), __FILE__)
		destination_folder = "#{@repoLocation}/.git/info/"
		# TODO: is cp_r required? cp enough?
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
		t1 = Time.now
		versions.each do |ver|			
			pvers = Version.is("#{@name}/#{ver}") #mcu-8.3.2\8.3.2.1.1			
			pvers.migrate(repo,View.is(view_name))
		end 
		t2 = Time.now
		t=t2-t1
		t=vt2-vt1
		mm, ss = t.divmod(60)           
		hh, mm = mm.divmod(60)          
		puts "Project #{@name} import OK; duration: %d:%d:%d seconds" % [hh, mm, ss]
		Log.write_log("Project #{@name} import OK; duration: %d:%d:%d seconds" % [hh, mm, ss])
	end
	
end  #Projectf

#----------------------------------------------------------------------------------------------

class Log
	
	def self.write_log(message)
		File.open('C:/Temp/confetti-migration.log', 'a') { |file| file.puts(Time.now.inspect + " " + message) }
	end
	def self.error_log(message)
		begin
			raise message 
		rescue Exception => e
		  self.class.write_log(e.message)
		  self.class.write_log(e.backtrace.join("\n"))		  
		ensure
		  puts "error, see c:/temp/confetti-migration.log for details"
		  exit
		end
	end
end

#----------------------------------------------------------------------------------------------

end # Import
end # Confetti1
