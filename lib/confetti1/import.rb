require_relative "import/base"
require_relative "import/clear_case"
require_relative "import/git"

require 'fileutils'
require 'yaml'
require 'pathname'

# require 'awesome_print'
# require 'colorize'
# require 'rake'

module Confetti
  module Import
    extend self



    def main(argv)
      arguments = argv
      command = arguments.shift
      @gits = []

      case  command
        when "--branch"
          branch = arguments.shift
          version = arguments.shift
          raise ArgumentError.new("Invalid version") unless version == '--version'
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
        else
          puts "Undefined attribute '#{command}'"
      end
    end



    def scan_to_yaml
      clear_case = ClearCase.new
      clear_case.scan_to_yaml
    end

  end
end
