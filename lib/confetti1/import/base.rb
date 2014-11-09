module Confetti1
  module Import
    class Base

      def confetti_config
        load_git_yaml("confetti_config.yml")
      end

      def ignore
        load_git_yaml("ignore.yml")
      end

      def vobs
        load_git_yaml("vobs.yml")
      end

      def store_vobs(vobs_list)
        
      end

    protected

      def command(cmd, *argv)
        output = `#{cmd} #{argv.join(" ")}`
        output.split("\n")
      end 

    private

      def load_git_yaml(conf)
       YAML.load_file(File.join("confetti_import", "config", conf))
     end

    end
  end
end