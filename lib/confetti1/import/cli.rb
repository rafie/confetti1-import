module Confetti1
  module Import
    class CLI 
      def init(*args)
        path = args.first[0]
        custome_name = args.first[1]
        app_name="confetti_import"
        working_app_name = custome_name || app_name
        app_pwd = path || Dir.pwd
        if File.exist? File.join(app_pwd, app_name, "config", "confetti_config.yml")
          Logger.log "Confetti exists. Exiting."
          return
        end
        FileUtils.cp_r(File.join(Confetti1::Import.root, app_name), app_pwd)
      end 

      def console(*args)
        require 'confetti1/import'
        begin
          require 'pry'
        rescue LoadError
          require 'rubygems'
          require 'pry'
        end
        Pry::CLI.parse_options
      end

      alias_method :c, :console

      def method_missing(meth, *args, &block)
        puts "Command not found: #{meth}"
      end

    end
  end
end