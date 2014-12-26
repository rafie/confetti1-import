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
      ENV['GIT_PATH'] || @@default_conf['git_path']
    end

    def view_path
      ENV['VIEW_PATH'] || @@default_conf['view_path']
    end

    def exclude_size
      ENV['EXCLUDE_SIZE'] || @@default_conf['exclude_size']
    end

    def ignore_list
      @@default_conf['ignore_list']
    end

    def clone_path
      ENV['CLONE_PATH'] || File.join(@@home_dir, 'workspace', 'cloned')
    end

    def handle_big
      ENV['HANDLE_BIG']
    end

  end

  def scan_view
    clear_case = ClearCase.new
    clear_case.scan
  end

  def scan_to_yaml
    clear_case = ClearCase.new
    clear_case.scan_to_yaml
  end

  def old_init
    clear_case = ClearCase.new
    sorted_files_list = clear_case.scan

    small_git = Git.new(path: File.join(ConfettiEnv.git_path, 'small'))
    small_git.init
    small_git.exclude!(sorted_files_list[:ignored])
    small_git.commit(sorted_files_list[:small_files], 'A cup of coffee')
    small_git.correct?(sorted_files_list[:small_files], 'small')

    if ConfettiEnv.handle_big
      big_git = Git.new(path: File.join(ConfettiEnv.git_path, 'big'))
      big_git.init
      big_git.exclude!(sorted_files_list[:ignored])
      big_git.commit(sorted_files_list[:big_files], 'A cup of coffee with a cake')
      big_git.correct?(sorted_files_list[:big_files], 'big')
    end
  end

  def init
    clear_case = ClearCase.new
    clear_case.scan_to_yaml
    small_git = Git.new(path: File.join(ConfettiEnv.git_path, 'small'))

    small_git.init
    small_git.exclude!(YAML.load_file(File.join(ConfettiEnv.home, 'config', 'ignored.yml')))
    small_map = YAML.load_file(File.join(ConfettiEnv.home, 'config', 'small.yml'))
    small_map.each_pair do |version, files|
      puts " ---> commiting #{version}".green.bold
      small_git.commit(files, version)
    end
    small_git.correct?(small_map.values.flatten, 'small')
  end

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

end                                                