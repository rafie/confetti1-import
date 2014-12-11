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


  def find_versions
    version_inpt = AppConfig.clear_case[:versions_input_folder]
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

  def build_versions
    versions_config = YAML.load_file File.join CONFETTI_HOME, 'config', 'versions.yml'
    configspecs = []
    puts
    puts "Found #{versions_config['locations'].size} locations:"
    puts
    puts versions_config['locations'].join("\n")
    puts "-".ljust(80, '-')
    versions_config["locations"].each do |versions_location|
      print "#{'Processing ' + versions_location.to_s.ljust(60, '.')}\r"
      configspecs += Dir.glob(File.join(versions_location, '**', '*')).select{|v| v =~ /configspec.txt$/}
      print "#{'Processing ' + versions_location.to_s.ljust(60, '.')}[  #{'done'.green.bold}  ]\r"
      puts
    end #versions_map
    puts
    puts "Processing files and reading configspecs"
    puts
    versions_db = []
    brocken = []
    version_item = {}
    clear_case = ClearCase.new(false)
    configspecs.each do |configspec|
      configspec_node = clear_case.configspec(configspec).detect{|cs| cs[:vob] =~ /mcu/ or cs[:vob] =~ /vcgw/}
      if configspec_node.nil?
        puts "Was now processed #{configspec}. MCU or VGCW vobs are not found".red.bold
        brocken << configspec
        next
      end
      version_item[:path] = configspec
      version_item[:version] = configspec_node[:version]
      version_item[:name] = configspec_node[:vob]
      versions_db << version_item
    end
    #---------------------------------------------------------------------------------------------------
    # (\d{1,}\.){4,}\d{1,}\/configspec.txt$
    #puts ""
    File.open(File.join(CONFETTI_HOME, 'config', 'brocken.yml'), 'w'){|f|f.write brocken.to_yaml}
    File.open(File.join(CONFETTI_HOME, 'config', 'configspecs.yml'), 'w'){|f|f.write configspecs.to_yaml}
    File.open(File.join(CONFETTI_HOME, 'config', 'versions_db.yml'), 'w'){|f|f.write version_item.to_yaml}
  end

end                                                