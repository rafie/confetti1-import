module Confetti1Import
  class CLI  

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

    def confspec(*args)
      puts ClearCase.new.configspec
    end

    def init_for(*args)
      Confetti1Import.init_for(args.first)
    end

    def method_missing(meth, *args, &block)
      puts "Command not found: #{meth}"
    end

  end
end