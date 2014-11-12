require "confetti1/import/base"
require "confetti1/import/version"
require "confetti1/import/cli"
require "confetti1/import/clear_case"
require "confetti1/import/confetti_git"
require "confetti1/import/config"
require 'fileutils'
require 'yaml'
require 'git'

module Confetti1
  module Import

    Config.load!(File.join("config", "confetti_config.yml"))

    def self.root
      File.expand_path File.join('..', '..', '..'), __FILE__
    end

    def self.load_config(attribute)
      YAML.load_file()
    end

    def self.version
      VERSION
    end

    def self.add_vob(vob)
      clear_case = ClearCase.new
      selected_vob = clear_case.configspec.select{|cs|cs[:vob] == vob.first}.first
      config = Base.new.confetti_config
      
      view_name = config["clear_case"]["view"]["name"]
      view_location = config["clear_case"]["view"]["location"]
      vob_path = File.join(view_location, view_name, selected_vob[:vob])
      git_location = File.join(Dir.pwd, "vobs", selected_vob[:vob], ".git")
      
      confetti_git = ConfettiGit.new(vob_path, git_location)
      confetti_git.add_all
    end

    def self.all
    end

    module Logger
      def self.log(message)
        puts message
      end
    end

  end
end                                                