module Confetti1Import
  class CLI 
    def init(*args)
      app_name="confetti_import"
      working_app_name = app_name
      app_pwd = Dir.pwd
      if File.exist? File.join(app_pwd, app_name, "config", "confetti_config.yml")
        Logger.log "Confetti exists. Exiting."
        return
      end
      FileUtils.cp_r(File.join(Confetti1::Import.root, app_name), app_pwd)
    end 

    def console(*args)
      require 'confetti1_import'
      begin
        require 'pry'
      rescue LoadError
        require 'rubygems'
        require 'pry'
      end
      Pry::CLI.parse_options
    end

    alias_method :c, :console

    def confspec
      puts ClearCase.new.configspec
    end

    def vob_to_git(*args)
      Confetti1::Import.add_vob(args.first)
    end

    def method_missing(meth, *args, &block)
      puts "Command not found: #{meth}"
    end

  end
end