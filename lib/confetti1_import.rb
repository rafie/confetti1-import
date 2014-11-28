#require 'rubygems'
require "confetti1_import/base"
require "confetti1_import/cli"
require "confetti1_import/clear_case"
require "confetti1_import/git"
require 'fileutils'
require 'yaml'
require 'awesome_print'
require 'colorize'
require 'pathname'

module Confetti1Import
  extend self

  CONFETTI_HOME = File.expand_path(File.join("..", ".."), __FILE__)
  CONFETTI_WORKSPACE = File.join CONFETTI_HOME,"workspace" 

  
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
  end

  #TODO: Remove this, it is not actual
  def init(for_what={})
    clear_case = ClearCase.new
    git = Git.new
    current_configspec = clear_case.configspec
    if for_what.empty?
      puts "Imorting #{current_configspec.size} VOBs..."
      clear_case.configspec.each_with_index do |cs|
        git.init! cs[:vob]
        git.exclude!
        git.commit_a! "Commit for #{cs[:version]}"
        git.tag cs[:version]
      end
    else
      selected_vob = current_configspec.select{|cs| cs[:vob] == for_what}
      puts "Oops, seems to be we've lost this VOB."; return if selected_vob.empty?
      git.init! selected_vob
      git.exclude!
      git.commit_a! "Commit for #{selected_vob[:version]}"
      git.apply_tag! selected_vob[:version]
    end
  end
  #---</TODO>

  def versions_to_git(vob)
    git = Git.new
    clear_case = ClearCase.new
    git.itit! vob
    working_folder = AppConfig.clear_case[:versions_input_folders]
    Dir.glob(File.join(working_folder, "**")) do |branch|
      branch_name = File.read(File.join(branch, 'int_branch.txt')).chop
      git.branch ({name: branch_name})
      git.checkout(branch_name)
      Dir.glob(File.join(branch, "**")) do |version|
        clear_case.configspec = File.join(version, "configspec.txt")
        git.exclude!
        version_name = version.split(/(\/)|(\\)/).last
        git.commit_a("#{version_name}")
        git.tag("v#{version_name}")
      end
      puts "$git checkout master".cyan
    end
  end

  def read_versions(path_to_versions)

  end

end                                                