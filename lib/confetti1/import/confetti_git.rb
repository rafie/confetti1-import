module Confetti1
  module Import
    class ConfettiGit < Base

      # Initialize .git folder with working tree inside CC VOB
      # vob_path: path to sources inside VOB
      # git_path: path to .git folder storage
      def initialize(vob_path, git_path)
        @ignored = ignored["ignore"]
        @git_path = git_path
        @vob_path = vob_path
        @git_dot_folder = git_path 

        unless Dir.exist? File.join(@git_path, ".git")
          FileUtils.makedirs @git_path
          command("git", "--git-dir=#{@git_path}", "--work-tree=#{vob_path}", "init")
        end
        @git_dot_folder
      end

      def ignore
        exclude
      end

      def add_all
        exclude
        
        git_operation = labda{|op|command "git", op, "#{all ? '.' : files.join(' ')}"}
        files_to_add
        
      end

      def commit!(all=true, message="Confetti commit")
        command "git", "commit", "#{all ? '-a': ''}", "-m\"#{message}\""
      end

      def status

        select_liles = Proc.new do |git_files, mask| 
          git_files.select{|o| o =~ mask}.map{|o| o.gsub(mask, '')}
        end

        to_be_commited = lambda{|git_files, mode| select_liles.call(git_files, /#{mode}\s\s/)}
        to_be_added = lambda{|git_files, mode| select_liles.call(git_files, /\s#{mode}\s/)}
        untracked = lambda{|git_files, mode| select_liles.call(git_files, /\?\?\s/)}
        
        out = command "git", "status", "--porcelain"
        {
          staged: {
            modified:   to_be_commited.call(out, 'M'),
            deleted:    to_be_commited.call(out, 'D'),
            renamed:    to_be_commited.call(out, 'R'),
            copied:     to_be_commited.call(out, 'C')
          },
          not_staged:{
            modified:   to_be_added.call(out, 'M'),
            deleted:    to_be_added.call(out, 'D'),
            renamed:    to_be_added.call(out, 'R'),
            copied:     to_be_added.call(out, 'C')
          },
          new_files: {untracked: untracked}
        }
      end  

    protected

      def exclude
        puts "Path to GIT: #{@git_dot_folder}"
        puts "excluding filed:"
        puts @ignored.join("\n")
        File.open(File.join(@git_dot_folder, 'info', 'exclude'), 'w') do |f|
          f.write @ignored.join("\n")
        end
      end

    end
  end
end