module Confetti1Import
  class Git < Base

    attr_reader :vob_working_tree

    def initialize
      @git_folder = AppConfig.git[:path]
      @view_root = File.join(AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name])
      @ignored = AppConfig.ignore_list
      @clone_path = File.expand_path AppConfig.git[:clone]
    end

    def init_view
      @git_view_dot_folder = File.join(@git_vob_folder, '.git')
      FileUtils.mkdir_p(@git_vob_folder)

      git "--git-dir=#{@git_vob_dot_folder} --work-tree=#{@view_root} init"
      in_directory(@git_vob_folder){git 'commit --allow-empty -m"initial commit"'}
    end

    def exclude!
      exclude_path = File.join(@git_vob_dot_folder, 'info')
      if File.exists?(File.join(exclude_path,  'exclude'))
        excluded_list = File.read(File.join(aexclude_path,  'exclude')).split(/\n/)
        return  if @ignored == excluded_list
      else
        FileUtils.mkdir_p(exclude_path)
      end
      puts "Excluding not needed files: #{@ignored.inspect}"
      File.open(File.join(exclude_path,  'exclude'), 'w') do |f|
        f << @ignored.join("\n")
      end
    end

    def commit_a!(message="Confetti commit")
      in_directory(@git_vob_folder) do
        exclusive_status.each do |st_file|
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
      in_directory(@git_vob_folder){git "tag", tag}
    end

    def branch(branch_name)
      in_directory(@git_vob_folder){git "branch", branch_name}
    end

    def checkout(thing, b={})
      in_directory(@git_vob_folder) do 
        if b[:b]
          git "checkout -b", thing
        else
          git "checkout", thing
        end
      end
    end

    def master
      in_directory(@git_vob_folder) do
        git "checkout master"
      end
    end

    def correct?(repo_name)
      test_clone
      raise "Repository is not cloned for texting" unless Dir.exist? @cloned_repository
      vob_pwd = File.join @view_root, @vob

      ignored = @ignored + [".git/"]

      result_glob = Dir.glob("#{@cloned_repository}/**/*").map{|rg| rg.gsub("#{@cloned_repository}/", "")}
      source_glob = Dir.glob("#{vob_pwd}/**/*").map{|sg| sg.gsub("#{vob_pwd}/", "")}

      result_list = Rake::FileList.new(result_glob){|rg| ignored.each{|i| rg.exclude i}}
      source_list = Rake::FileList.new(source_glob){|sg| ignored.each{|i| sg.exclude i}}

      res = result_list == source_list
      if res
        puts "Repository is imported correctly".green.bold
      else
        puts "Repository is imported incorrectly".red.bold
        puts "-------- Lost files -------------------------------------------------------"
        puts (source_list - result_list).join("\n")
        puts "---------------------------------------------------------------------------"
      end
      FileUtils.rm_rf(@cloned_repository)
      res
    end

    def on_branch?(branch)
      in_directory(@git_vob_folder) do
        current_branch = git("branch").detect{|br| br =~ /^\*/}.gsub(/^\*\s/, "")
        current_branch == branch
      end
    end

  private

    def test_clone
      @cloned_repository = File.join @clone_path, @vob
      git "clone", @git_vob_folder, @cloned_repository
    end

    def exclusive_status
      @exclude_list = []
      output = in_directory(@git_vob_folder) do
        res = git('status --porcelain').map{|st|st.gsub(/^(.{1,}\s)/, "")}.map do |out|
          path_to = File.join(@vob_working_tree, out)
          if Dir.exist?(File.join(@vob_working_tree, out)) 
            @exclude_list << Dir.glob(File.join(path_to, '**', '*'))
          else
            path_to
          end
        end

      end
      status = []
      output.flatten.each do |f| 
        if File.size(f) > AppConfig.git[:ignore_size]
          puts "File '#{f}' is too large for import".yellow
        elsif File.exist? f
          status << f
        else
          puts "'f' if not a file or directory".red
        end
      end
      status
    end

    def git(*params)
      in_directory(@git_vob_folder) do
        command 'git', params.join("\s")
      end
    end

  end
end