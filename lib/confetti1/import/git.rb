module Confetti1
  module Import
    class Git < Base

      def initialize(args={})
        @git_path        = args[:path] || ConfettiEnv.git_path

        @git_dot_folder  = File.join(@git_path, '.git')
        @exclude_file    = File.join(@git_dot_folder, 'info', 'exclude')
        @view_path       = ConfettiEnv.view_path
        @ignore_list     = ConfettiEnv.ignore_list
        @exclude_size    = ConfettiEnv.exclude_size
        @clone_path      = File.join(ConfettiEnv.workspace, 'testing_repo')
      end

      def init
        return @git_dot_folder if File.directory? @git_path
        FileUtils.mkdir_p(@git_path)
        git "--git-dir=#{@git_dot_folder} --work-tree=#{@view_path} init"
        in_directory(@git_path){git 'commit --allow-empty -m"initial commit"'}
        @git_dot_folder
      end

      def exclude!(file_list)
        puts "Excluding files bigger then #{@exclude_size} bites"
        to_exclude = file_list
        File.open(@exclude_file, 'w'){|f| f.write(to_exclude.join("\n"))}
      end

      def commit(file_list, message)
        in_directory(@git_dot_folder) do
          file_list.each do |file|
            puts "Adding #{file}"
            git "add \"#{file}\""
          end
          unless staged_files.empty?
            git "commit -m\"#{message}\""
          else
            puts "Nothing to commit"
          end
        end
      end

      def commit_a!(message)
        in_directory(@git_dot_folder) do
          git 'add .'
          git "commit -m\"#{message}\""
        end
      end

      def correct?(file_list, place=nil)
        puts "Started test"
        test_clone(place)
        raise "Repository is not cloned for testing" unless Dir.exist? @cloned_repository
        small_files = file_list.map{|fl| fl.gsub(@view_path, '')}
        cloned_files = in_directory(@cloned_repository){command('git ls-files')}.map{|cl| cl.gsub(@cloned_repository, '')}

        
        puts "Small size: #{small_files.size}"
        puts "Cloned size: #{cloned_files.size}"

        escaped_small_files = small_files.map{|sf|sf.gsub(/\/|\\/, '')}.sort
        escaped_cloned_files = cloned_files.map{|cf|cf.gsub(/\/|\\/, '')}.sort
        correctness = escaped_small_files==escaped_cloned_files
        if correctness
          puts "Version imported correctly".green.bold
        else
          puts "Version imported not correctly".red.bold
        end
        correctness
      end

      def on_branch?(branch)
        in_directory(@git_dot_folder) do
          current_branch = git("branch").detect{|br| br =~ /^\*/}.gsub(/^\*\s/, "")
          current_branch == branch
        end
      end

      def tag(name)
        in_directory(@git_dot_folder){git("tag #{name}")}
      end

      def tag_exist?(tag)
        tags = git("tag -l")
        tags.detect{|t| t==tag}
      end

      def branch_exist?(branch)
        in_directory(@git_dot_folder) do
          !!git("branch").map{|br| br.gsub(/\s|\*/, '')}.detect{|br| br == branch}
        end
      end

      def checkout!(thing, params="")
        git 'checkout', params, thing
      end




    private

      def clean_up!
        FileUtils.rm_rf @cloned_repository
      end

      def test_clone(path=nil)
        @cloned_repository = File.join([ConfettiEnv.clone_path, path].compact)
        if Dir.exist?(@cloned_repository)
          FileUtils.rm_rf(@cloned_repository)
        end
        git "clone", @git_dot_folder, @cloned_repository
      end

      def status
        output = in_directory(@view_path){git('status --porcelain').map{|st| st =~ /^\s\w\s/}}
      end

      def staged_files
        in_directory(@view_path){git('status --porcelain').map{|st| st =~ /^\w\s\s/}}.compact
      end

      def git(*params)
        in_directory(@git_path) do
          command 'git', params.join("\s")
        end
      end

    end
  end
end