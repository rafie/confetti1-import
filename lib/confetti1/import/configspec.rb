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
		#@cspecfile=cspecfile	
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
				#system("cleartool mount #{vn}")
				puts "VOB #{vn} mounted"
			end
		end
		@view_name=viewName
		cmd = System.command("cleartool setcs -tag #{viewName} #{@cspecfile}")
	end
	
	def migrate(repo)
		@vobs_arr.each do |vob|		
			vn=vob
			vn[0]="/"
			puts "Adding VOB #{vob}"
			repo.add("m:/#{@view_name}#{vob}")
			puts "VOB #{vob} added"	
			# git --git-dir=d:\view\.git --work-tree=m:\view
		end
		puts "committing version #{@vers}..."
		repo.commit("migrated from clearcase",@vers)
		puts "version imported successfully"
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
	
	def create(repoLocation, viewName)
		@repoLocation = repoLocation
		@viewName = viewName
		system("git --git-dir=#{repoLocation}/.git --work-tree=m:/#{viewName} init")
	end
	
	def add(dir)
		cmd = System.command("git --git-dir=#{@repoLocation}/.git --work-tree=m:/#{@viewName} add #{dir}")
		unless cmd.ok?
				raise "git add #{dir} failed. Import stopped." 
		end
	end
	
	def commit(message,tag)
		#cmd = System.command("git --git-dir=#{@repoLocation}/.git commit -m \"#{message}\"", :nolog)		
		cmd = System.command("git --git-dir=#{@repoLocation}/.git commit -m \"#{message}\"")
		System.command("git --git-dir=#{@repoLocation}/.git tag #{tag}")
		unless cmd.ok?
			raise "Commit error, import failed!" 
		end
	end
	
	def add_ignore_list
		file_path = File.expand_path(File.join("..", "..", "..","..","exclude"), __FILE__)
		destination_folder = "#{@repoLocation}/.git/info/"
		FileUtils.cp_r(file_path, destination_folder, :remove_destination => true)

	end
	
end

  
end # Import
end # Confetti
