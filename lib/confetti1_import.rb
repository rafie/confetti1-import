require "confetti1_import/base"
require "confetti1_import/cli"
require "confetti1_import/clear_case"
require "confetti1_import/confetti_git"
require 'fileutils'
require 'yaml'

module Confetti1Import
  extend self

  module Settings
    extend self
    attr_reader :settings

    @settings = YAML.load_file(File.join("config", "confetti_config.yml"))
    @settings.each_pair do |sk, sv|
      define_method(sk.to_sym) do
        sv.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end
    end
  end

  def add_vob(vob)
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



  def logme(message)
    puts message
  end

end                                                