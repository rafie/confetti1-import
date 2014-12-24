module Confetti1Import
  class Git < Base

    def initialize
<<<<<<< Updated upstream
      @git_path        = ConfettiEnv.git_path
      @git_dot_folder  = File.join(@git_path, '.git')
      @exclude_file    = File.join(@git_dot_folder, 'info', 'exclude')
      @view_path       = ConfettiEnv.view_path
      @ignore_list     = ConfettiEnv.ignore_list
      @exclude_size    = ConfettiEnv.exclude_size
      @clone_path      = File.join(AppConfig.workspace, 'testing_repo')
=======
      @git_folder = File.expand_path(AppConfig.git[:path])
      @view_root = File.join(AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name])
     
      @clone_path = File.expand_path AppConfig.git[:clone]
      @exclude_file_size = AppConfig.git[:ignore_size]
>>>>>>> Stashed changes
    end

    def init_or_get_repository_for_view

      puts "Import started.."
      unless File.exist?(@exclude_file_location)
        puts "Initialing empty git repository.."
        FileUtils.mkdir_p(@git_folder)
        git "--git-dir=#{@git_dot_folder} --work-tree=#{@view_path} init"
        in_directory(@git_path){git 'commit --allow-empty -m"initial commit"'}
      end
      puts "Initialized"
      @git_dot_folder
    end

    def exclude!
<<<<<<< Updated upstream
      puts "Excluding files bigger then #{@exclude_size} bites"
      to_exclude = @ignore_list
      in_directory(@view_path) do
        Dir.glob(File.join('**', '*')).each do |view_file|
          next if
          if File.exist?(view_file) and (File.size(view_file) > @exclude_size)
=======
      puts "Excluding files bigger then #{@exclude_file_size} bites"
      to_exclude = []
      in_directory(@view_root) do
        Dir.glob(File.join('**', '*')).each do |view_file|
          if File.exist?(view_file) and (File.size(view_file) > @exclude_file_size.to_i)
>>>>>>> Stashed changes
            to_exclude << view_file
          end
        end
      end
      File.open(@exclude_file_location, 'w'){|f| f.write(to_exclude.join("\n"))}
    end

    def commit_a!(message="Confetti commit")
      puts "Commiting to repository"
      in_directory(@view_root) do
        git 'add .'  
        git "commit -m\"#{message}\""
      end
    end

    def correct?
      puts "Started test"
      test_clone
      raise "Repository is not cloned for testing" unless Dir.exist? @cloned_repository

      result_glob = Dir.glob(File.join(@cloned_repository, '**', '*'))
      result_files = result_glob.select{|rg|File.exist?(rg)}

      source_glob = Dir.glob(File.join(@view_root, '**', '*'))
<<<<<<< Updated upstream
      source_files = source_glob.select{|sg|File.exist?(sg) and (File.size(sg) < @exclude_size)}
=======
      source_files = source_glob.select{|sg| File.size(sg) < AppConfig.git[:ignore_size]}
>>>>>>> Stashed changes
      
      puts "Result size: #{result_files.size}"
      puts "Source size: #{source_files.size}"
      puts "Clean up?"
      gets 
      clean_up!

      # diffs =  (source_glob - result_glob)
      # puts "------------------------> #{(source_glob == result_glob).inspect}"
      # File.open('diff_list.txt', 'w'){|f|f.write(diffs.join("\n"))}
      # File.open('source_list.txt', 'w'){|f|f.write(source_glob.join("\n"))}
      # File.open('result_list.txt', 'w'){|f|f.write(result_glob.join("\n"))}
    end

    def on_branch?(branch)
      in_directory(@view_root) do
        current_branch = git("branch").detect{|br| br =~ /^\*/}.gsub(/^\*\s/, "")
        current_branch == branch
      end
    end


  private

    def clean_up!
      FileUtils.rm_rf @git_folder
      FileUtils.rm_rf @cloned_repository
    end

    def test_clone
      @cloned_repository = File.join @clone_path, "cloned"
      git "clone", @git_path, @cloned_repository
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