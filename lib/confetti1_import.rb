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
require 'rake'

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

  def init(for_what={})
    clear_case = ClearCase.new
    git = Git.new
    current_configspec = clear_case.configspec
    puts "------------------------------------------->"
    puts current_configspec
    if for_what.empty?
      puts "Imorting #{current_configspec.size} VOBs..."
      clear_case.configspec.each_with_index do |cs|
        git.init! cs[:vob]
        git.exclude!
        git.commit_a! "Commit for #{cs[:version]}"
        git.tag cs[:version]
        git.correct?
      end
    else
      selected_vob = current_configspec.detect{|cs| cs[:vob] == for_what}
      puts "Oops, seems to be we've lost this VOB."; return if selected_vob.empty?
      git.init! selected_vob[:vob]
      git.exclude!
      git.commit_a! "Commit for #{selected_vob[:version]}"
      git.correct?
    end
  end

  def import_to_git
    git = Git.new
    clear_case = ClearCase.new
    working_folder = AppConfig.clear_case[:versions_input_folders]
    Dir.glob(File.join(working_folder, "**")) do |mcu|
      tag_name = File.read(File.join(mcu, 'int_branch.txt')).chop
      Dir.glob(File.join(mcu, "**")) do |version|
        puts "Applying configspec for MCU-#{version}-----------------------------------"
        puts ""
        clear_case.configspec=File.expand_path(File.join(version, "configspec.txt"))
        puts "Reading applyed configspec"
        configspec = clear_case.configspec
        excluded = false

        configspec.each do |cs|
          print "#{'Commiting sources for ' + cs[:vob].ljust(50)}\r"
          begin
            git.init! cs[:vob]
            excluded = true; git.exclude! unless excluded
            git.commit_a! cs[:version]
            git.tag tag_name
          rescue Exception => e
            print "#{'Commiting sources for' + cs[:vob].ljust(50, '.')}[  #{'fail'.red.bold}  ]\r"
            puts "Error:"
            puts e.inspect
            return
          end
          print "#{'Commiting sources for' + cs[:vob].ljust(50, '.')}[  #{'done'.green.bold}  ]\r"
          puts ""
        end
      end
    end
  end

end                                                