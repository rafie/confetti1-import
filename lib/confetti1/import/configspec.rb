require 'yaml'
require 'Bento'

module Confetti1
module Import

class ConfigSpec
	include Bento::Class

	constructors :is
	members :cspecfile, :vobs_arr, :view_name
	
	def is(cspecfile)
		@cspecfile=cspecfile
		out = File.read(cspecfile).split("/element \/|element \\/")
		@vobs_arr = Array.new(out.length)
		out.shift
		out.each_with_index {|val, index| @@vobs_arr[index]=val.squeeze(" ").split(" ")[1] }
		@@vobs_arr.reject!(&:nil?).reject!(&:empty?)
		
	end
	
	def vobs
		@vobs_arr
	end
	
	def applyToView(viewName)
		Dir.chdir("M:/#{viewName}") do
			system("cleartool setcs #{@cspecfile}")
		end
	end
	def migrate(repo)
		@vobs.each do |vob|
			repo.add("m:/#{@view_name}/#{vob}")
			# git --git-dir=d:\view\.git --work-tree=m:\view
		end
		repo.commit("migrated from clearcase")
	end
end
	
	
class GitRepo
	include Bento::Class

	constructors :create
	members :repoLocation, :viewName

	def create(repoLocation,viewName)
		@repoLocation=repoLocation
		@viewName=viewName
		system("git --git-dir=#{repoLocation}.git --work-tree=m:/#{viewName}")
	end
	
	def add(dir)
		system("git --git-dir=#{@repoLocation}/.git --work-tree=m:/#{@viewName} add #{dir}")
	end
	
	def commit(message)
		system("git commit-m \"#{message}\"")
	end
	
	def add_ignore_list(pathToYAMLIgnoreListFile)
		data=YAML.load(File.read(pathToYAMLIgnoreListFile));
		File.open("#{@repoLocation}/.git/info/exclude", 'a') do |file|
			data[ignore_list].each.do |item|				  
				file.write(item) #TODO: manipulate ignore string
			end
		end
		
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
