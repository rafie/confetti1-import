require 'yaml'
require 'Bento'
require 'fileutils'

module Confetti1
module Import

class ConfigSpec
	include Bento::Class

	constructors :is
	members :cspecfile, :vobs_arr, :view_name
	
	def is(cspecfile)
		@cspecfile=cspecfile		
		out = IO.readlines(cspecfile)
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
		@view_name=viewName
		system("cleartool setcs -tag #{viewName} #{@cspecfile}")
	end
	
	def migrate(repo)
		@vobs_arr.each do |vob|
		unless File.directory?("m:/#{@view_name}#{vob}")
			vn=vob
			vn[0]="\\"
			system("cleartool mount #{vn}")
		end
		vn=vob
		vn[0]="/"
		puts "Adding VOB #{vob}"
		repo.add("m:/#{@view_name}#{vob}")
		puts "VOB #{vob} added"				
	
			# git --git-dir=d:\view\.git --work-tree=m:\view
		
		puts "committing version..."
		repo.commit("migrated from clearcase")
	end
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
		system("git --git-dir=#{@repoLocation}/.git --work-tree=m:/#{@viewName} add #{dir}")
	end
	
	def commit(message)
		system("git --git-dir=#{@repoLocation}/.git commit -m \"#{message}\"")
	end
	
	def add_ignore_list
		file_path = File.expand_path(File.join("..", "..", "..","..","exclude"), __FILE__)
		destination_folder = "#{@repoLocation}/.git/info/"
		FileUtils.cp_r(file_path, destination_folder, :remove_destination => true)
#		FileUtils.cp(file_path, destination_folder)
	end
	
end

#(1)
#repo = GitRepo.create(...)
## system("git --git-dir=d:\view\.git --work-tree=m:\view init
#repo.add_ignore_list(yaml_ignore_list)

#(2)
#view.setcs(cspec_file)
#cspec = Configspec.new(file)
#cspec.vobs.each do |vob|
#	repo.add("m:/#{view}/#{vob}")
	# git --git-dir=d:\view\.git --work-tree=m:\view
#end
#repo.tag("...")




# command line:
#import create-repo --where DIR
#import version --cpsec FILE --repo GIT-DIR --name VER

  
end # Import
end # Confetti
