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

    def confspec(*argv)
      args = argv.flatten
      puts "--> #{args.first}"
      if args.empty?
        ap ClearCase.new.configspec
      else
        ap ClearCase.new.configspec.select{|cs| cs[:vob] == args.first}
      end
    end

    def init(*argv)
      #args = argv.flatten
      Confetti1Import.init
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
      Confetti1Import.find_versions
    end


    def build_versions(*argv)
      Confetti1Import.build_versions
    end

    def originate_versions(*argv)
      Confetti1Import.originate_versions
    end

    def import(*argv)
      Confetti1Import.import_to_git
    end

    def rm_rf(*argv)
      FileUtils.rm_rf AppConfig.git[:path]
    end

    def method_missing(meth, *args, &block)
      puts "Command not found: #{meth}"
    end

  end
end