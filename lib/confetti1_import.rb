require "confetti1_import/base"
require "confetti1_import/cli"
require "confetti1_import/clear_case"
require "confetti1_import/git"
require 'fileutils'
require 'yaml'

module Confetti1Import
  extend self

  module AppConfig
    extend self
    attr_reader :settings

    @settings = YAML.load_file(File.join("config", "confetti_config.yml"))
    @settings.each_pair do |sk, sv|
      define_method(sk.to_sym) do
        unless sv.is_a? Array
          sv.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        else
          sv
        end
      end
    end
    puts "Settings -----------------------------------------------------------------------------------"
    puts @settings.to_yaml
    puts "--------------------------------------------------------------------------------------------"
  end

  def init_for(vob)
    confetti_git = Git.new
    confetti_git.init! vob
    confetti_git.exclude!
    confetti_git.commit! true
  end

end                                                