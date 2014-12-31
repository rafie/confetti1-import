require "confetti1/import/base"
require "confetti1/import/cli"
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

      def versions_path
        ENV['VERSIONS_PATH'] || File.join(@@home_dir, 'workspace', 'versions')
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
      forest_location = File.expand_path(File.join(ConfettiEnv.home, "versions"))
      current_wd = Dir.getwd

      wrong = {unprocessed: [], not_found:[]}

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
            wrong[:not_found] << location
            next 
          end
          Dir.glob(File.join('**', 'configspec.txt')).each do |cs_location|
            begin
              splited_location = cs_location.split(/(\\)|\//)
              cs_index = splited_location.rindex{|sl|sl=~ /configspec.txt/i}
              unless cs_index
                puts "Wrong location: '#{cs_location}'".red.bold
                next
              end
              unless splited_location[cs_index-1] =~ /^((\d+\.)+)(\d+)$/
                puts "Version location has wrong format: #{splited_location}".yellow.bold
                next
              end
              db_version_place = File.join(int_branch_location, splited_location[cs_index-1])
              Dir.mkdir(db_version_place) unless Dir.exist?(db_version_place)
              FileUtils.cp(cs_location, File.join(db_version_place, 'configspec.txt'))
            rescue Exception => e
              puts "#{e.class}: #{e.message}".red.bold
              next
            end
            File.open(File.join(int_branch_location, 'origin.txt'), 'w'){|f| f.write(clear_case.originate(cs_location))}
            File.open(File.join(int_branch_location, 'int_branch.txt'), 'w'){|f| f.write("#{int_branch}_int_br")}
          end
        end
      end
      Dir.chdir current_wd
    end

    # def originate_versions
    #   puts "Originating"
    #   clear_case = ClearCase.new
    #   puts "--> #{File.join(ConfettiEnv.home, 'versions', '**')}"
    #   Dir.glob(File.join(ConfettiEnv.home, 'versions', '**')).each do |branch|
    #     next unless File.directory?(branch)
    #     Dir.glob(File.join(branch, '**')).each do |label_path|
    #       puts "Label path ->>>>>>>>  #{label_path}"
    #       next unless File.directory? label_path
    #       puts File.expand_path(File.join(label_path, 'configspec.txt'))
    #       clear_case.configspec = File.expand_path(File.join(label_path, 'configspec.txt'))
    #       label = label_path.split(/\/|\\/).last
    #       clear_case.inside_view do
    #         puts `ruby #{ConfettiEnv.home}/brsource.rb mcu_#{label}`
    #         #clear_case.find_origin "#{label}"
    #       end
    #     end
    #   end 
      
    # end
    
    def import
      git = Git.new
      clear_case = ClearCase.new
      # TODO: -->
      working_folder = AppConfig.clear_case[:versions_input_folder]
      # <--
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

  end   
end                                             