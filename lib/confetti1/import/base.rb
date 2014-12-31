module Confetti1
  module Import
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

      def command(cmd, *argv)
        output = `#{cmd} #{argv.join(" ")}`
        output.split("\n")
      end

    end#class
  end#Import
end#Confetti1