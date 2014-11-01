require "confetti1/import/version"
require 'fileutils'
require "git"

module Confetti1
  module Import

    class GitHandler
      
      def initialize(cc_view, git_uri, repo_name="our_repo")
        @cc_veiw_path = cc_view
        @repo_name = repo_name
        @git_uri = git_uri
      end

      def init!
        Dir.chdir @cc_veiw_path
        files_end_dirs = Dir.glob("**/*")

        @dirs =  files_end_dirs.select{|f| Dir.exist?("#{@cc_veiw_path}/#{f}")}
        @files = files_end_dirs.select{ |f| !Dir.exist?("#{@cc_veiw_path}/#{f}") and File.exist?("#{@cc_veiw_path}/#{f}")}
        
        @git_repo = Git.clone @git_uri, @repo_name
        @path_to_repo = "#{@cc_veiw_path}/#{@repo_name}"
      end

      def add_all
        Dir.chdir @path_to_repo
        FileUtils.mkdir_p @dirs
        @files.each do |view_file|
          path_to_file = "#{@cc_veiw_path}/#{view_file}"
          path_to_repo_file = "#{@path_to_repo}/#{view_file}"
          FileUtils.copy_file(path_to_file, path_to_repo_file)
          @git_repo.add path_to_repo_file
        end
      end

      def commit_and_push!
        @git_repo.commit('First commit from script!')
        @git_repo.pull
        @git_repo.push
      end 

      def cleanup!
        FileUtils.rm_rf @path_to_repo
      end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
    end

  end
end                                                