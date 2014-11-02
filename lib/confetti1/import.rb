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

        @dirs =  files_end_dirs.select{|f| Dir.exist?(File.join(@cc_veiw_path, f))}
        @files = files_end_dirs.select{ |f| !Dir.exist?(File.join(@cc_veiw_path, f)) and File.exist?(File.join(@cc_veiw_path, f))}
        begin
          @git_repo = Git.clone @git_uri, @repo_name
        rescue Git::GitExecuteError
          Dir.chdir @cc_veiw_path
          @git_repo = Git.open @repo_name
        end
        @path_to_repo = git_repo.dir.path
        @any_changes = false 
        if File.exist?(File.join(@path_to_repo, ".gitignore")) 
          @ignored = File.read(File.join(@path_to_repo, ".gitignore")).split("\n")
        else
          @ignored = []
        end 
      end

      def add_all
        Dir.chdir @path_to_repo
        FileUtils.mkdir_p @dirs

        add_file = Proc.new do |file, is_new|
          FileUtils.copy_file(File.join(@cc_veiw_path, file), File.join(@path_to_repo, file)) if is_new
          @git_repo.add File.join(@path_to_repo, file)
          @any_changes = true
        end

        @files.each do |view_file|
          path_to_file = File.join @cc_veiw_path, view_file
          path_to_repo_file = File.join @path_to_repo, view_file

          #TODO: Not DRY way. 
          # Git gem has :status method, but it works in another way then it described in docs 
          if File.exist? path_to_repo_file
            next if @ignored.include? view_file
            next unless File.exist? path_to_file
            next if FileUtils.compare_file(path_to_file, path_to_repo_file)
            add_file.call(view_file, true)
          end

          next unless File.exist? path_to_repo_file
          add_file.call(view_file, false)
          #--- end
        end
      end

      def commit_and_push!
        #TODO: Shold be replaced to Clear Case metadata
        if @any_changes
          @git_repo.commit('First commit from script!')
          @git_repo.pull
          @git_repo.push
          @git_woking_tree_clean = true
        end
      end 

      def cleanup!
        FileUtils.rm_rf @path_to_repo
      end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
    end

  end
end                                                