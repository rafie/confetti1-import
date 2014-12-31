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
        puts "Import started.."
        unless File.exist?(@exclude_file)
          puts "Initialing empty git repository.."
          puts @git_dot_folder
          FileUtils.mkdir_p(@git_path)
          git "--git-dir=#{@git_dot_folder} --work-tree=#{@view_path} init"
          in_directory(@git_path){git 'commit --allow-empty -m"initial commit"'}
        end
        puts "Initialized"
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
          git "commit -m\"#{message}\""
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
        in_directory(@view_root) do
          current_branch = git("branch").detect{|br| br =~ /^\*/}.gsub(/^\*\s/, "")
          current_branch == branch
        end
      end


    private

      def clean_up!
        FileUtils.rm_rf @cloned_repository
      end

      def test_clone(path=nil)
        @cloned_repository = File.join([ConfettiEnv.clone_path, path].compact)
        git "clone", @git_dot_folder, @cloned_repository
      end

      def status
        output = in_directory(@view_path){git('status --porcelain').map{|st| st =~ /^\s\w\s/}}
      end

      def git(*params)
        in_directory(@git_path) do
          command 'git', params.join("\s")
        end
      end

    end
  end
end