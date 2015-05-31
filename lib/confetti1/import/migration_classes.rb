require 'yaml'
require 'Bento'
require 'fileutils'

module Confetti1
module Import

class ConfigSpec
	include Bento::Class

	constructors :is
	members :cspecfile, :vobs_arr, :view_name, :vers
	
	def is(cspecfile)			
		@vers=cspecfile
		@cspecfile=File.expand_path(File.join("..", "..", "..","..","versions",cspecfile,"configspec.txt"), __FILE__)
		out = IO.readlines(@cspecfile)
		out.reject! { |c| c[0,7]!="element" }
		out.shift
		@vobs_arr = Array.new(out.length)		
		out.each_with_index {|val, index| @vobs_arr[index]=val.squeeze(" ").split(" ")[1].chomp('...').chop }
		@vobs_arr				
	end
	
	def vobs
		@vobs_arr
	end
	
	def applyToView(viewName)
		@vobs_arr.each do |vob|
			unless File.directory?("m:/#{viewName}#{vob}")
				vn=vob
				vn[0]="\\"
				puts "VOB #{vn} must be mounted...please wait..."
				cmd = System.command("cleartool mount #{vn}")
				unless cmd.ok?
					raise "Mounting error, import failed!" 
				end				
				puts "VOB #{vn} mounted"
			end
		end
		@view_name=viewName
		cmd = System.command("cleartool setcs -tag #{viewName} #{@cspecfile}")
	end
	
	def migrate(repo)
		ignore = File.read(File.join(repo.location,".git", "info", "exclude"))
		puts @vers
		vt1 = Time.now
		@vobs_arr.each do |vob|	
			unless ignore.include? vob	
				vn=vob
				vn[0]="/"
				puts "Adding VOB #{vob}"
				repo.add("m:/#{@view_name}#{vob}")
				puts "VOB #{vob} added"			
			else
				puts "VOB #{vob} skipped"
			end
		end
		puts "committing version #{@vers}..."
		repo.commit("migrated from clearcase",@vers)
		vt2 = Time.now
		vt3=vt2-vt1
		h=(vt3/3600).to_i
		vt3=vt3-(h*3600)
		m=(vt3/60).to_i
		vt3=vt3-(m*60)
		puts "version #{@vers} imported successfully. Duration : #{h} hour(s), #{m} minutes and #{vt3} seconds"
	end
end
	
	
class GitRepo
	include Bento::Class

	constructors :is, :create
	members :repoLocation, :viewName

	def is(repoLocation, viewName)
		@repoLocation = repoLocation
		@viewName = viewName
	end
	def location
		@repoLocation
	end
	def vn
		@viewName
	end
	def create(repoLocation, viewName)
		@repoLocation = repoLocation
		@viewName = viewName
		system("git --git-dir=#{repoLocation}/.git --work-tree=m:/#{viewName} init")
		system("git commit --allow-empty -m \"initial commit\"")
	end
	
	def add(dir)
		cmd = System.command("git --git-dir=#{@repoLocation}/.git --work-tree=m:/#{@viewName} add #{dir}")
		unless cmd.ok?
				System.command("git --git-dir=#{@repoLocation}/.git reset")
				raise "git add #{dir} failed. Import cancelled and rolledback to last commit." 
		end
	end
	
	def commit(message,tag)
		cmd = System.command("git --git-dir=#{@repoLocation}/.git commit -m \"#{message}\"")		
		unless cmd.ok?
		puts "commit failed...rollback running..."
			System.command("git --git-dir=#{@repoLocation}/.git reset")
			raise "Commit error, import cancelled and rolledback to last commit" 
		end
		System.command("git --git-dir=#{@repoLocation}/.git tag #{tag}")
	end
	
	def add_ignore_list
		file_path = File.expand_path(File.join("..", "..", "..","..","exclude"), __FILE__)
		destination_folder = "#{@repoLocation}/.git/info/"
		FileUtils.cp_r(file_path, destination_folder, :remove_destination => true)

	end
	
end #GitRepo

class Project
	include Bento::Class
	constructors :is
	members :name, :path, :arr_ver

	def is(name)
		@name = name
		@path=File.expand_path(File.join("..", "..", "..","versions",@name))
	end
	
	def versions		
		Dir.chdir(@path) do
			@arr_ver=Dir["*"].reject{|o| not File.directory?(o)}
		end		
		@arr_ver=@arr_ver.map {|x| x.split('.').map{|y| y.to_i}}.sort.map {|x| x.join('.')}
		@arr_ver
	end
	
	def migrate(repo,origin: nil)
		puts ("will execute git --git-dir=#{repo.location}/.git branch #{@name} #{origin}" )
		system("git --git-dir=#{repo.location}/.git branch #{@name}")
		puts ("will execute git --git-dir=#{repo.location}/.git symbolic-ref HEAD refs/heads/#{@name}")
		system("git --git-dir=#{repo.location}/.git symbolic-ref HEAD refs/heads/#{@name}")
		
		versions.each do |ver|
			cspec = ConfigSpec.is("#{@name}/#{ver}") #mcu-8.3.2\8.3.2.1.1
			cspec.applyToView(repo.vn)
			cspec.migrate(repo)
		end 
	end
	
end  #Projectf
end # Import
end # Confetti
