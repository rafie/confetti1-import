module Confetti1Import
  class Git < Base

    attr_reader :vob_working_tree

    def initialize
      @git_folder = AppConfig.git[:path]
      @view_root = File.join(AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name])
      @ignore_list = AppConfig.ignore_list
      @clone_path = File.expand_path AppConfig.git[:clone]
      @exclude_file_size = AppConfig.git[:ignore_size]
    end

    def init_or_get_repository_for_view
      @git_dot_folder ||= File.join(@git_folder, '.git')
      @exclude_file_location ||= File.join(@git_dot_folder, 'info', 'exclude')
      puts "Import started.."
      unless File.exist?(@exclude_file_location)
        puts "Initialing empty git repository.."
        FileUtils.mkdir_p(@git_folder)
        git "--git-dir=#{@git_dot_folder} --work-tree=#{@view_root} init"
        in_directory(@git_folder){git 'commit --allow-empty -m"initial commit"'}
      end
      puts "Initialized"
      @git_dot_folder
    end

    def exclude!
      puts "Excluding files bigger then #{@exclude_file_size} bites"
      to_exclude = @ignore_list
      in_directory(@view_root) do
        Dir.glob(File.join('**', '*')).each do |view_file|
          if File.exist?(view_file) and (File.size(view_file) > @exclude_file_size.to_i)
            to_exclude << view_file
          end
        end
      end
      File.open(@exclude_file_location, 'w'){|f| f.write(to_exclude.join("\n"))}
    end

    def commit_a!(message="Confetti commit")
      in_directory(@view_root) do
        status.each do |st_file|
          if st_file =~ /\w/
            git 'add', "\"#{st_file}\""
          else
            git 'add', st_file
          end
        end
        git "commit -m\"#{message}\""
      end
    end

    def tag(tag)
      in_directory(@view_root){git "tag", tag}
    end

    def branch(branch_name)
      in_directory(@view_root){git "branch", branch_name}
    end

    def checkout(thing, b={})
      in_directory(@view_root) do 
        if b[:b]
          git "checkout -b", thing
        else
          git "checkout", thing
        end
      end
    end

    def master
      in_directory(@view_root) do
        git "checkout master"
      end
    end

    def correct?(repo_name)
      test_clone
      raise "Repository is not cloned for texting" unless Dir.exist? @cloned_repository
      result_glob = Dir.glob("#{@cloned_repository}/**/*").map{|rg| rg.gsub("#{@cloned_repository}/", "")}
      source_glob = Dir.glob("#{vob_pwd}/**/*").map{|sg| sg.gsub("#{@view_root}/", "")}
      puts source_glob - result_glob
    end

    def on_branch?(branch)
      in_directory(@view_root) do
        current_branch = git("branch").detect{|br| br =~ /^\*/}.gsub(/^\*\s/, "")
        current_branch == branch
      end
    end

  private

    def test_clone
      @cloned_repository = File.join @clone_path, @vob
      git "clone", @view_root, @cloned_repository
    end

    def status
      output = in_directory(@view_root) do
      git('status --porcelain').map{|st| st =~ /^\s\w\s/}
    end

    def git(*params)
      in_directory(@git_folder) do
        command 'git', params.join("\s")
      end
    end

  end
end