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

  module ConfettiEnv
    extend self

    @@home_dir = File.expand_path(File.join("..", ".."), __FILE__)
    @@default_conf = YAML.load_file(File.join(@@home_dir, "config", "confetti_config.yml"))

    def home
      @@home_dir
    end

    def workspace
      File.join(@@home_dir, 'workspace')
    end

    def git_path
      ENV["GIT_PATH"] || @@default_conf['git_path']
    end

    def view_path
      ENV["VIEW_PATH"] || @@default_conf['view_path']
    end

    def exclude_size
      ENV['EXCLUDE_SIZE'] || @@default_conf['exclude_size']
    end

    def ignore_list
      @@default_conf['ignore_list']
    end

  end

  def scan_view
    clear_case = ClearCase.new
    clear_case.scan
  end

  def init
    git = Git.new
    git.init_or_get_repository_for_view
    git.exclude!
    git.commit_a! "Flat commit. Demo version"
    git.correct?
  end

  #TODO: Apply new configuration
  # def import_to_git
  #   git = Git.new
  #   clear_case = ClearCase.new
  #   working_folder = AppConfig.clear_case[:versions_input_folder]
  #   Dir.glob(File.join(working_folder, "**")).each do |mcu|

  #     branch_name = File.read(File.join(mcu, 'int_branch.txt')).strip

  #     Dir.glob(File.join(mcu, "**")).each do |version|

  #       next unless Dir.exist? version
  #       configspec_path = File.join version, 'configspec.txt'
  #       raise "Can not found configspec" unless File.exist? configspec_path
        
  #       puts "Applying configspec for #{version}"
  #       clear_case.configspec = File.expand_path configspec_path
  #       configspec = clear_case.configspec
  #       mcu_vob = configspec.detect{|cs|cs[:vob] == 'mcu'}

  #       configspec.each do |cs|
  #         git.init! cs[:vob]
  #         unless git.on_branch? branch_name
  #           git.checkout branch_name, b: true
  #         else
  #           git.checkout branch_name
  #         end

  #         print "#{'Commiting sources for ' + cs[:vob].ljust(50)}\r"
  #         #clear_case.mount cs[:vob]
  #         raise "Cannot init" unless git.init! cs[:vob]

  #         print "#{'Commiting sources for' + cs[:vob].ljust(50, '.')}[  #{'done'.green.bold}  ]\r"
  #         puts ""
  #         git.exclude!
  #         git.commit_a! cs[:version]
  #         git.tag version
  #       end
  #     end
  #   end
  # end

  def build_versions
    versions_config = YAML.load_file(File.join(ConfettiEnv.home, 'config', 'versions.yml'))
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

  # def originate_versions
  #   versions = YAML.load_file(File.join(CONFETTI_HOME, 'config', 'versions_db.yml'))
  #   versions.each_value do |branch|
  #     branch.each do |version|
  #       `ruby brsource.rb #{version['name']}-#{version['version']}`
  #     end
  #   end
  # end

end                                                