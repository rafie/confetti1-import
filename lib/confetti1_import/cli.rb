module Confetti1Import
  class CLI < Base
    
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

    def init(*argv)
      Confetti1Import.init
    end

    def build_versions(*argv)
      Confetti1Import.build_versions
    end

    def originate_versions(*argv)
      Confetti1Import.originate_versions
    end

    def scan(*argv)
      Confetti1Import.scan_view
    end

    def scan_to_yaml(*argv)
      Confetti1Import.scan_view_to_yaml
    end

    def method_missing(meth, *args, &block)
      puts "Command not found: #{meth}"
    end

  end
end