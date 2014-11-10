module Confetti1
  module Import
    class Confetti1Git < Base

      def init(git_path, vob_path)
        @git_path = git_path
        unless Dir.exist? File.join(@git_path, ".git")
          FileUtils.makedirs @git_path
          command("git", "--git-dir=#{@git_path}", "--work-tree=#{vob_path}", "init")
        end
        @git = Git.init @git_path
      end

      def add_all
        @git.status.changed
        # @git.add File.join(@path_to_repo, file)
  

        # @files.each do |view_file|
        #   path_to_file = File.join @cc_veiw_path, view_file
        #   path_to_repo_file = File.join @path_to_repo, view_file

        #   #TODO: Not DRY way. 
        #   # Git gem has :status method, but it works in another way then it described in docs 
        #   if File.exist? path_to_repo_file
        #     next if @ignored.include? view_file
        #     next unless File.exist? path_to_file
        #     next if FileUtils.compare_file(path_to_file, path_to_repo_file)
        #     add_file.call(view_file, true)
        #   end

        #   next unless File.exist? path_to_repo_file
        #   add_file.call(view_file, false)
        #   #--- end

        # end
      end

      def commit!
        # @git.commit('First commit from script!')
        # @git_woking_tree_clean = true
      end 

    end
  end
end