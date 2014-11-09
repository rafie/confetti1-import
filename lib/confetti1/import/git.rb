module Confetti1
  module Import
    class Git

      def init(vob)
        #git --git-dir=c:\repo --work-tree=m:\myview init
        command("git", "--git-repo", "--work-tree")
      end

      def add
      end

    end
  end
end