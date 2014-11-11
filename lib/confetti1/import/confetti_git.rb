module Confetti1
  module Import
    class ConfettiGit < Base

      def initialize
        #@ignored = ignored["ignore"]
      end

      def init(git_path, vob_path)
        @git_path = git_path
        @git_dot_folder = File.join(git_path, ".git") 
        unless Dir.exist? File.join(@git_path, ".git")
          FileUtils.makedirs @git_path
          command("git", "--git-dir=#{@git_path}", "--work-tree=#{vob_path}", "init")
        end
        @git_dot_folder
      end

      def exclude
        File.open(File.join(@git_dot_folder, 'info', 'exclude'), 'w') do |f|
          f.puts @ignored.join("\n")
        end
      end

      def add(all=false, files=[])
        command "git", "add", "#{all ? '.' : files.join(' ')}"
      end

      def commit!(all=true, message="Confetti commit")
        command "git", "commit", "#{all ? '-a': ''}", "-m\"#{message}\""
      end

      def status
        status_mode = lambda do |status, mode|
          status.select{|o| o =~ /#{mode}\s+/}.map{|o| o.gsub(/#{mode}\s+/, '').gsub(/\s/, '')}
        end
        out = command "git", "status", "--porcelain"
        {
          untracked:  status_mode.call(out, /\?\?/),
          modified:   status_mode.call(out, 'M'),
          deleted:    status_mode.call(out, 'D'),
          renamed:    status_mode.call(out, 'R'),
          copied:     status_mode.call(out, 'C')
        }
      end  

    end
  end
end