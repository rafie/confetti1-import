require "confetti1/import/base"
require "confetti1/import/clear_case"
require "confetti1/import/git"

require 'fileutils'
require 'yaml'
require 'awesome_print'
require 'colorize'
require 'pathname'
require 'rake'

module Confetti1
  module Import
    extend self

    module ConfettiEnv
      extend self

      @@home_dir = File.expand_path(File.join("..", "..", ".."), __FILE__)
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

      def versions_path
        ENV['VERSIONS_PATH'] || File.join(@@home_dir, 'versions')
      end

      def log_path
        File.join(@@home_dir, 'log') 
      end

      def output_path
        File.join(@@home_dir, 'output')
      end

    end

    def main(argv)
      arguments = argv
      command = arguments.shift
      case  command
        when "--init"
          git = Git.new
          git.init
        when "--build-versions"
          self.build_versions
        when "--version"
          raise ArgumentError.new("Path to version is empty") if arguments.empty?
          self.commit_version(arguments.first)
        when "--branch"
          branch = arguments.shift
          version_arg = arguments.shift
          raise ArgumentError.new("Invalid version") unless version_arg == '--version'
          version = arguments.shift
          tag_arg = arguments.shift
          raise ArgumentError.new("Invalid tag") unless version_arg == '--tag'
          tag = arguments.shift
          version_folder_name = branch.split("_").first
          self.commit_version(File.join(version_folder_name, version), tag, branch)
        when "--product"
          TODO
        else
          puts "Undefined attribute '#{command}'"
      end
    end

    def commit_version(path, tag=nil branch='master')
      make_git = Proc.new do |type|
        raise ArgumentError.new("Only :small or :big allowed") unless (type==:small) or (type==:big)
        git = Git.new(path: File.join(ConfettiEnv.git_path, 'small'))
        git.checkout!(branch, '-b') unless git.branch_exist?(branch)
        git.exclude!(YAML.load_file(File.join(ConfettiEnv.output_path, 'ignored.yml')))
        files_map = YAML.load_file(File.join(ConfettiEnv.output_path, "#{type.to_s}.yml"))
        files_map.each_pair do |version, files|
          files_git.commit(files, version)
        end
        correctness = git.correct?(small_map.values.flatten, type.to_s)
        if correctness
          if tag
            git.tag(tag)
          end
        end
      end

      cs_location = File.join(versions_path, args.split("\/"), 'configspec.txt')
      raise Errno::ENOENT.new("Configspec not found - '#{cs_location}'") unlless File.exist? cs_location
      clear_case = ClearCase.new
      clear_case.configspec = cs_location
      clear_case.scan_to_yaml

      if ConfettiEnv.handle_big
        make_git.call(:small)
        make_git.call(:big)
      else
        make_git.call(:small)
      end

    end

    def scan_to_yaml
      clear_case = ClearCase.new
      clear_case.scan_to_yaml
    end

    def build_versions
      versions_config = YAML.load_file(File.join(ConfettiEnv.home, 'config', 'versions.yml'))
      forest_location = File.expand_path(File.join(ConfettiEnv.home, "versions"))
      wrong_locations = []
      wrong_formats   = []
      Dir.glob(File.join(forest_location, "**")).each{|fl|FileUtils.rm_rf(fl)}
      current_wd = Dir.getwd
      clear_case = ClearCase.new
      versions_config.each_pair do |int_branch, locations|
        puts "-> for #{int_branch}"
        int_branch_location = File.join(forest_location, int_branch.downcase)

        Dir.mkdir(int_branch_location) unless Dir.exist?(int_branch_location)
        File.open(File.join(int_branch_location, 'dir'), 'w'){|f|f.write(int_branch_location)}

        locations.each do |location|
          begin
            Dir.chdir location
          rescue Errno::ENOENT => e
            puts e.message.to_s.red
            wrong_locations << location
            next 
          end

          Dir.glob(File.join('**', 'configspec.txt')).each do |cs_location|
            begin
              splited_location = cs_location.split(/(\\)|\//)
              cs_index = splited_location.rindex{|sl|sl=~ /configspec.txt/i}
              unless cs_index
                puts "Wrong location: '#{cs_location}'".red.bold
                wrong_locations << cs_location
                next
              end
              unless splited_location[cs_index-1] =~ /^((\d+\.)+)(\d+)$/
                puts "Version location has wrong format: #{splited_location}".yellow.bold
                wrong_formats << cs_location
                next
              end
              db_version_place = File.join(int_branch_location, splited_location[cs_index-1])
              Dir.mkdir(db_version_place) unless Dir.exist?(db_version_place)
              FileUtils.cp(cs_location, File.join(db_version_place, 'configspec.txt'))
            rescue Exception => e
              puts "#{e.class}: #{e.message}".red.bold
              next
            end

            unless File.exist?(File.join(int_branch_location, 'int_branch.txt'))
              begin
                origin = clear_case.originate(File.join(db_version_place, 'configspec.txt'))
                File.open(File.join(int_branch_location, 'origin.txt'), 'w'){|f| 
                  f.write(origin)
                }
              rescue Exception => e
                puts e.class
                puts e.message
              end
              
              File.open(File.join(int_branch_location, 'int_branch.txt'), 'w'){|f| f.write("#{int_branch}_int_br")}
            end

          end
        end
        
      end
      Dir.chdir current_wd
      puts "Cleaning up.."
      Dir.glob(File.join(ConfettiEnv.versions_path, '**')).each do |version|
        next unless File.directory? version
        if Dir.glob("#{version}/**/").size <= 1
          puts " --> #{version} has no labels and will be removed".red
          puts "--------------------------------------------------------"
          puts Dir.glob(File.join(version, "**", "*")).join("\n")
          puts "--------------------------------------------------------"
          FileUtils.rm_rf(version)
        end
      end
      File.open(File.join(ConfettiEnv.log_path, 'wrong_locations.txt'), 'w'){|f|f.write(wrong_locations.join("\n"))}
      File.open(File.join(ConfettiEnv.log_path, 'wrong_formats.txt'), 'w'){|f|f.write(wrong_formats.join("\n"))}
    end


    # def import
    #   clear_case = ClearCase.new
    #   Dir.glob(File.join(ConfettiEnv.versions_path, '**')).each do |version|
    #     int_branch = File.read(File.join(version, 'int_branch.txt'))
    #     origin_path = File.join(version, 'origin.txt')
    #     Dir.glob(File.join(version, "**")).each do |label|
    #       next unless File.directory?(label)
    #       if Dir.glob(File.join(label, "*")).empty?
    #         puts "Label #{label} has not configspec".red.bold
    #         next
    #       end

    #       puts "================================================"
    #       puts Dir.glob(File.join(label, "*"))

    #     end
    #   end
    # end

  end   
end                                             