module Confetti1Import
  module SelfTest

    def self.init_correctness(git_vob)
      test_pwd = File.join CONFETTI_WORKSPACE, "testing_repo", git_vob
      vob_pwd = File.join CONFETTI_HOME, AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name], git_vob
      ignored = AppConfig.ignore_list + [".git/"]

      FileUtils.makedirs test_pwd
      cloned = Git.clone(File.join(AppConfig.git[:path], git_vob), test_pwd)
      
      result_glob = Dir.glob("#{cloned}/**/*").map{|rg| rg.gsub("#{test_pwd}/", "")}
      source_glob = Dir.glob("#{vob_pwd}/**/*").map{|sg| sg.gsub("#{vob_pwd}/", "")}

      # current_dir = Dir.getwd

      # Dir.chdir test_pwd
      # result_glob = `git ls-files`
      # Dir.chdir vob_pwd
      # source_glob =  `git ls-files`
      # Dir.chdir current_dir

      result = result_glob
      source = source_glob.each do |sg| 
        puts ignored.select{|i| sg =~ Regexp.new(i)} 
      end

      puts "----------------------------------------------------------------------"
      puts result.inspect
      puts "----------------------------------------------------------------------"
      puts source.inspect
      puts "----------------------------------------------------------------------"
      puts ignored
      FileUtils.rm_rf test_pwd
    end

  end

end