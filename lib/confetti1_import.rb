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

  def init
    clear_case = ClearCase.new
    git = Git.new
    current_configspec = clear_case.configspec
    git.init_or_get_repository_for_view
    git.exclude!
    git.commit_a! "Flat commit. Demo version"
    git.correct?
  end

  def import_to_git
    git = Git.new
    clear_case = ClearCase.new
    working_folder = AppConfig.clear_case[:versions_input_folder]
    Dir.glob(File.join(working_folder, "**")).each do |mcu|

      branch_name = File.read(File.join(mcu, 'int_branch.txt')).strip

      Dir.glob(File.join(mcu, "**")).each do |version|

        next unless Dir.exist? version
        configspec_path = File.join version, 'configspec.txt'
        raise "Can not found configspec" unless File.exist? configspec_path
        
        puts "Applying configspec for #{version}"
        clear_case.configspec = File.expand_path configspec_path
        configspec = clear_case.configspec
        mcu_vob = configspec.detect{|cs|cs[:vob] == 'mcu'}

        configspec.each do |cs|
          git.init! cs[:vob]
          unless git.on_branch? branch_name
            git.checkout branch_name, b: true
          else
            git.checkout branch_name
          end

          print "#{'Commiting sources for ' + cs[:vob].ljust(50)}\r"
          #clear_case.mount cs[:vob]
          raise "Cannot init" unless git.init! cs[:vob]

          print "#{'Commiting sources for' + cs[:vob].ljust(50, '.')}[  #{'done'.green.bold}  ]\r"
          puts ""
          git.exclude!
          git.commit_a! cs[:version]
          git.tag version
        end
      end
    end
  end

  def build_versions
    versions_config = YAML.load_file File.join CONFETTI_HOME, 'config', 'versions.yml'
    forest_location = File.expand_path(File.join(Dir.getwd, "versions"))
    current_wd = Dir.getwd
    wrong = {unprocessed: [], not_found:[]}
    versions_config.each_pair do |int_branch, locations|
      puts "-> for #{int_branch}"
      int_branch_location = File.join(forest_location, int_branch.downcase)
      Dir.mkdir(int_branch_location)
      File.open(File.join(int_branch_location, 'dir'), 'w'){|f|f.write(int_branch_location)}
      locations.each do |location|
        begin
          Dir.chdir location
        rescue Errno::ENOENT => e
          puts e.message.to_s.red
          wrong[:not_found] << location
          next 
        end
        Dir.glob(File.join('**', 'configspec.txt')).each do |cs_location|
          splited_location = cs_location.split(/(\\)|\//)
          if splited_location.size == 2
            db_version_place = File.join(int_branch_location, splited_location.first)
            Dir.mkdir(db_version_place)
            FileUtils.cp(cs_location, File.join(db_version_place, 'configspec.txt'))
          else
            puts "#{cs_location} has subfolders. Processing next location".yellow
            wrong[:unprocessed] << cs_location
          end
        end
      end
    end
    Dir.chdir current_wd
    File.open(File.join(forest_location, 'unprocessed.yml'), 'w'){|f|f.write(wrong.to_yaml)}
  end

  def originate_versions
    versions = YAML.load_file(File.join(CONFETTI_HOME, 'config', 'versions_db.yml'))
    versions.each_value do |branch|
      branch.each do |version|
        `ruby brsource.rb #{version['name']}-#{version['version']}`
      end
    end
  end

end                                                