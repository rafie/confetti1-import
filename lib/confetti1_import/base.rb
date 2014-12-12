module Confetti1Import
  class Base
  
  protected

    def in_directory(dir_to_run, &block)
      raise "No block given" unless block_given?
      current_dir = Dir.pwd 
      Dir.chdir dir_to_run
      res = yield
      Dir.chdir current_dir
      res
    end


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

    def command(cmd, *argv)
      output = `#{cmd} #{argv.join(" ")}`
      output.split("\n")
    end


  end
end