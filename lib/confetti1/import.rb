require "confetti1/import/version"
require "confetti1/import/cli"
require 'fileutils'
require "git"
require 'yaml'

module Confetti1
  module Import

    def self.version
      VERSION
    end

    def self.root
      File.expand_path File.join('..', '..', '..'), __FILE__
    end

    module Logger
      def self.log(message)
        puts message
      end
    end

  end
end                                                