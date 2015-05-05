require_relative 'configspec.rb'
module Confetti1
module Import


#repo = GitRepo.create("C:/git","ddavar_view2")
# system("git --git-dir=d:\view\.git --work-tree=m:\view init
#repo.add_ignore_list("C:/Users/ddavar/Desktop/confetti1-import-didier/config/confetti_config.yml")

puts IO.readlines(File.expand_path(File.join("..", "..", "..","..","exclude"), __FILE__))
#cs=ConfigSpec.is(cspec_file)
cspec = ConfigSpec.is("C:/Users/ddavar/Desktop/confetti1-import-didier/versions/mcu-8.3.2/8.3.2.1.3/configspec.txt")
#cspec.applyToView("ddavar_view2")
#cspec.migrate(repo)

end
end
