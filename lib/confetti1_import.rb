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

  #TODO: Remove this, it is not actual
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
      end
    else
      selected_vob = current_configspec.detect{|cs| cs[:vob] == for_what}
      puts "Oops, seems to be we've lost this VOB."; return if selected_vob.empty?
      git.init! selected_vob[:vob]
      git.exclude!
      git.commit_a! "Commit for #{selected_vob[:version]}"
    end
  end
  #---</TODO>

  def correct?(vob)
    test_pwd = File.join AppConfig.git[:path], "testing_repo", vob
    vob_pwd = File.join CONFETTI_HOME, AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name], vob
    ignored = AppConfig.ignore_list + [".git/"]

    FileUtils.makedirs test_pwd
    FileUtils.rm_rf test_pwd if Dir.exist? test_pwd
    cloned = Git.new.clone(File.join(AppConfig.git[:path], vob), test_pwd)
    result_glob = Dir.glob("#{cloned}/**/*").map{|rg| rg.gsub("#{test_pwd}/", "")}
    source_glob = Dir.glob("#{vob_pwd}/**/*").map{|sg| sg.gsub("#{vob_pwd}/", "")}
    result_list = Rake::FileList.new(result_glob){|rg| ignored.each{|i| rg.exclude i}}
    source_list = Rake::FileList.new(source_glob){|sg| ignored.each{|i| sg.exclude i}}
    FileUtils.rm_rf test_pwd
    res = result_list == source_list
    if res
      puts "Repository is imported correctly".green.bold
    else
      puts "Repository is imported uncorrectly".red.bold
    end
    res
  end

  def versions_to_git(vob)
    puts "Initializing import.."
    git = Git.new
    clear_case = ClearCase.new
    git.init! vob
    puts "GIT repozitory initialized"
    working_folder = AppConfig.clear_case[:versions_input_folders]
    puts "Starting versions import"
    Dir.glob(File.join(working_folder, "**")) do |branch|
      branch_name = File.read(File.join(branch, 'int_branch.txt')).chop
      puts "=> git branch '#{branch_name}'"
      puts git.branch(branch_name)
      puts "=> git checkout '#{branch_name}'"
      puts git.checkout(branch_name)
      Dir.glob(File.join(branch, "**")) do |version|
        version_name = version.split(/(\/)|(\\)/).last
        puts "Loading configspec for #{version_name}"
        clear_case.configspec=File.expand_path(File.join(version, "configspec.txt"))
        puts "Excluding unneed files files"
        git.exclude!
        puts "=> git commit -a -m\"#{version_name}\""
        puts git.commit_a!("#{version_name}")
        puts "=> git tag v#{version_name}"
        puts git.tag("v#{version_name}")
      end

      puts "=> git checkout master".cyan
      puts git.master
    end
  end

  def find_versions
    version_inpt = AppConfig.clear_case[:versions_input_folder]
    version_out = AppConfig.clear_case[:versions_outut_folder]
    puts Dir.glob("#{version_inpt}/**/*")
    input_map = []
    FileUtils.mkdir_p(version_out)
    Dir.glob("#{version_inpt}/**").each do |entry|
      entry_name = entry.split("/").last
      dir_path = File.read(File.join(entry, 'dir'))
      entry_clean_name = entry_name.split("-").first
      puts "------------------------------------ #{dir_path} #{Dir.exists?(dir_path) ? "Exists" : "Not exists"}"
      Dir.open(dir_path).entries.reject{|ee| !(ee =~ /(\d\.)+/)}.each do |cs_folder|
        source_cs = File.join(dir_path, cs_folder, 'configspec.txt')
        dst_cs = File.join(entry, cs_folder)
        FileUtils.mkdir_p dst_cs
        begin
          FileUtils.cp(source_cs, dst_cs)
        rescue Errno::ENOENT
          FileUtils.rm_rf dst_cs
          puts "File '#{source_cs}' was not found".red.bold
          next
        end
        File.open(File.join(entry, 'int_branch.txt'), 'w'){ |f| f << "#{entry_name}_int_br"}
        puts "Copied '#{source_cs}' to '#{dst_cs}'".green.bold
      end
    end
  end

  def read_versions(path_to_versions)

  end

end                                                