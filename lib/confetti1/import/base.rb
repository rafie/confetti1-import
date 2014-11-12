module Confetti1
  module Import
    class Base
      def command(cmd, *argv)
        output = `#{cmd} #{argv.join(" ")}`
        output.split("\n")
      end
    end
  end
end