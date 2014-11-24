module Confetti1Import
  class Base

    def init_correctness(git_vob)
      test_pwd = File.join CONFETTI_WORKSPACE, "testing_repo", git_vob
      vob_pwd = File.join CONFETTI_HOME, AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name], git_vob
      @ignored = AppConfig.ignore_list + [".git/"]

      FileUtils.makedirs test_pwd
      cloned = Git.clone(File.join(AppConfig.git[:path], git_vob), test_pwd)
      
      result_glob = Dir.glob("#{cloned}/**/*").map{|rg| rg.gsub("#{test_pwd}/", "")}
      source_glob = Dir.glob("#{vob_pwd}/**/*").map{|sg| sg.gsub("#{vob_pwd}/", "")}.reject do |path|
        next unless @ignored.select{|i| path =~ to_rxp(i)}.empty?
      end

      puts "----------------------------------------------------------------------"
      ap result_glob
      puts "----------------------------------------------------------------------"
      ap source_glob
      puts "----------------------------------------------------------------------"
      puts @ignored
      FileUtils.rm_rf test_pwd
    end
  
  private

    def to_rxp(path)
      res = path
      if res[-1] == "/"
        res[-1] = "\/*"
      end
      puts Regexp.new(res)
      Regexp.new(res)
    end

    def to_tree(path, name = nil)
      data = {:parent => (name || path)}
      data[:children] = children = []

      Dir.foreach(path) do |entry|
        next if entry == '..' or entry == '.' or entry == '.git'
        
        full_path = File.join(path, entry)
        if File.directory?(full_path)
          children << to_tree(full_path, entry)
        else
          children << entry
        end
      end
      data
    end

  private

    def command(cmd, *argv)
      output = `#{cmd} #{argv.join(" ")}`
      output.split("\n")
    end
  end
end