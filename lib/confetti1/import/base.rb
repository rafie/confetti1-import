module Confetti1
  module Import
    class Base

      def confetti_config
        load_yaml("confetti_config.yml")
      end

      def ignore
        load_yaml("ignore.yml")
      end

      def vobs
        load_yaml("vobs.yml")
      end

      def store_vobs(vobs_list)
        
      end

    protected

      def command(cmd, *argv)
        output = `#{cmd} #{argv.join(" ")}`
        output.split("\n")
      end 

    private

      def load_yaml(conf)
        conf_path = File.join("config", conf)
        #raise "Not in application" unless File.exist? conf_path
        YAML.load_file(File.join("config", conf))
     end

    end
  end
end