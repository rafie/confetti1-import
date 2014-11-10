module Confetti1
  module Import
    class Git < Base

      def init(git_path, vob_path)
        #git --git-dir=c:\repo --work-tree=m:\myview init
        unless Dir.exist? File.join(git_path, ".git")
          FileUtils.makedirs git_path
          #puts "git --git-dir=#{git_path} --work-tree=#{vob_path}"
          command("git", "--git-dir=#{git_path}", "--work-tree=#{vob_path}", "init")
        end
      end


    end
  end
end