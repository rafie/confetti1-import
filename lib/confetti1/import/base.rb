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

      def raw_command(cmd, *argv)
        cmd = "#{cmd} #{argv.join("\s")}"
        print "Running command: ".bold
        print cmd
        puts
        output = ""
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          exit_status = wait_thr.value
          if exit_status.success?
            output = stdout.read 
          else
            raise stderr.read
          end
        end
        output
      end

      def command(cmd, *argv)
        raw_command(cmd, argv).split("\n")
      end
      
    end
  end
end