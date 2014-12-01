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

    def confspec(*args)
      puts ClearCase.new.configspec
    end

    def init(*args)
      Confetti1Import.init(args.first)
    end

    def method_missing(meth, *args, &block)
      puts "Command not found: #{meth}"
    end


    def test(*argv)
      args = argv.flatten
      unless args.empty?
        Confetti1Import.correct?(argv.first)
      else
        puts "Please, specify VOB to test"
      end
    end

    def find_versions(*argv)
      ClearCase.find_versions(argv)
    end

    def import_git_from(*argv)
      vob = argv.flatten
      Confetti1Import.versions_to_git vob
    end

  end
end