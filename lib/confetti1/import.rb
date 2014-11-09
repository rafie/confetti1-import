require "confetti1/import/base"
require "confetti1/import/version"
require "confetti1/import/cli"
require "confetti1/import/clear_case"
require 'fileutils'
require 'yaml'

module Confetti1
  module Import

    def self.root
      File.expand_path File.join('..', '..', '..'), __FILE__
    end

    def self.load_config(attribute)
      YAML.load_file()
    end

    def self.version
      VERSION
    end


    module Logger
      def self.log(message)
        puts message
      end
    end

  end
end                                                