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

      def small_reposiroty
        File.join(self.git_path, 'small') || ENV['SMALL_REPOSITORY']
      end

      def big_repository
        File.join(self.git_path, 'big') || ENV['SMALL_REPOSITORY'] if handle_big
      end

      def git_repozitories
        [self.small_reposiroty, self.big_repository].compact
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

    module Logger
      extend self
      def log(message="")
        puts message
        File.open(File.join(ConfettiEnv.log_path, 'confetti.log'), 'a'){|f|f.puts "-------[#{Time.now}]---------\n#{message}"}
      end
    end

    def main(argv)
      arguments = argv
      command = arguments.shift
      @gits = []
      case  command
        when "--init"
          ConfettiEnv.git_repozitories.each do |repo|
            git = Git.new(path: repo)
            git.init
            @gits << git
          end
        when "--build-versions"
          self.build_versions
        when "--version"
          raise ArgumentError.new("Path to version is empty") if arguments.empty?
          self.commit_version(File.join(ConfettiEnv.versions_path, arguments.first.split(/\\|\//), 'configspec.txt'))
        when "--branch"
          branch = arguments.shift
          version_arg = arguments.shift
          raise ArgumentError.new("Invalid version") unless version_arg == '--version'
          version = arguments.shift
          tag_arg = arguments.shift
          raise ArgumentError.new("Invalid tag") unless tag_arg == '--tag'
          tag = arguments.shift
          version_folder_name = branch.split("_").first
          self.commit_version(File.join(version_folder_name, version), tag, branch)
        when "--product"
          version = arguments.shift
          version_location = File.join(ConfettiEnv.versions_path, version)

          origin = nil
          unless arguments.empty?
            origin_arg = arguments.shift
            if origin_arg == "--from-tag"
              origin = arguments.shift
              raise ArgumentError.new("'--from-tag' can not be empty") if origin.nil?
            end
          end

          version_glob = Dir.glob(File.join(version_location, '**', 'configspec.txt'))
          raise Errno::ENOENT.new("Invalid product version") if version_location.empty?
          int_branch = File.read(File.join(version_location, 'int_branch.txt'))

          version_glob.each do |label|
            larr = label.split(/\\|\//)
            tag = larr[larr.size-2]
            self.commit_version(label, tag, int_branch, origin)
          end
        when "--cleanup-git"
          FileUtils.rm_rf(ConfettiEnv.git_path)
        when "--cleanup-clone"
          FileUtils.rm_rf(ConfettiEnv.clone_path)
        when "--cleanup-all"
          FileUtils.rm_rf(ConfettiEnv.git_path)
          FileUtils.rm_rf(ConfettiEnv.clone_path)
        else
          puts "Undefined attribute '#{command}'"
      end
    end


    def commit_version(cs_location, tag=nil, branch='master', origin_tag=nil)
      make_commit = Proc.new do |repo, type|
        git = Git.new(path: repo)
        unless origin_tag.nil?
          if git.tag_exist?(origin_tag) 
            git.checkout!(origin_tag)
          else
            raise ArgumentError.new("Tag '#{origin_tag}' not found in repository")
          end
        end
        git.checkout!(branch, '-b') unless git.branch_exist?(branch)
        git.exclude!(YAML.load_file(File.join(ConfettiEnv.output_path, 'ignored.yml')))
        files_map = YAML.load_file(File.join(ConfettiEnv.output_path, "#{type}.yml"))
        files_map.each_pair do |version, files|
          git.commit(files, version)
        end
        correctness = git.correct?(files_map.values.flatten, type)
        if correctness
          if tag
            git.tag(tag)
          end
        end
      end

      make_commit.call(ConfettiEnv.small_reposiroty, 'small')
      make_commit.call(ConfettiEnv.big_repository, 'big') if ConfettiEnv.handle_big

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
            Logger.log e.message.to_s.red
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
                Logger.log e.class
                Logger.log e.message
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
          Logger.log Dir.glob(File.join(version, "**", "*")).join("\n")
          puts "--------------------------------------------------------"
          FileUtils.rm_rf(version)
        end
      end
      File.open(File.join(ConfettiEnv.log_path, 'wrong_locations.txt'), 'w'){|f|f.write(wrong_locations.join("\n"))}
      File.open(File.join(ConfettiEnv.log_path, 'wrong_formats.txt'), 'w'){|f|f.write(wrong_formats.join("\n"))}
    end

  end   
end                                             