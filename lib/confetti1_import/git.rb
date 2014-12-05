module Confetti1Import
  class Git < Base

    attr_reader :vob_working_tree

    def initialize
      @git_folder = AppConfig.git[:path]
      @view_root = File.join(AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name])
      @ignored = AppConfig.ignore_list
      @clone = AppConfig.git[:clone]
    end

    def init!(vob)
      @vob = vob
      @vob_working_tree = File.join @view_root, @vob
      @git_vob_dot_folder = File.join @git_folder , @vob, ".git"

      unless Dir.exist? vob_working_tree
        puts '########  DEBUG ###########################################################'
        puts '-------- working tree not found -------------------------------------------'
        puts vob
        puts '---------------------------------------------------------------------------'
        @git_vob_dot_folder
        puts '###########################################################################'
        return false
      end

      unless Dir.exist? @git_vob_dot_folder
        FileUtils.makedirs @git_vob_dot_folder
        git "--git-dir=#{@git_vob_dot_folder} --work-tree=#{@vob_working_tree} init"
        in_repo{git 'commit --allow-empty -m"initial commit"'}
      end
      @git_vob_dot_folder
    end

    def exclude!
      exclude_path = File.join(@git_vob_dot_folder, 'info', 'exclude')
      excluded_list = File.read(exclude_path).split(/\n/)
      return  if @ignored == excluded_list
      puts "Excluding not needed files: #{@ignored.inspect}"
      File.open(File.join(@git_vob_dot_folder, 'info', 'exclude'), 'w') do |f|
        f << @ignored.join("\n")
      end
    end

    def commit_a!(message="Confetti commit")
      in_repo do
        git "add ."
        git "commit -a -m\"#{message}\""
      end
    end

    def tag(tag)
      in_repo{git "tag", tag}
    end

    def branch(branch_name)
      in_repo{git "branch", branch_name}
    end

    def checkout(thing)
      in_repo do
        res = git "checkout", thing
      end
    end

    def master
      in_repo do
        git "checkout master"
      end
    end

    def status
      in_repo do
        select_files = Proc.new do |files, mask| 
          files.select{|o| o =~ mask}.map{|o| o.gsub(mask, '')}
        end

        to_be_commited = lambda{|git_files, mode| select_files.call(git_files, /#{mode}\s\s/)}
        to_be_added = lambda{|git_files, mode| select_files.call(git_files, /\s#{mode}\s/)}
        untracked = lambda{|git_files| select_files.call(git_files, /\?\?\s/)}
        
        git "status", "--porcelain"
        return {
          staged: {
            modified:   to_be_commited.call(out, 'M'),
            deleted:    to_be_commited.call(out, 'D'),
            renamed:    to_be_commited.call(out, 'R'),
            copied:     to_be_commited.call(out, 'C')
          },
          unstaged:{
            modified:   to_be_added.call(out, 'M'),
            deleted:    to_be_added.call(out, 'D'),
            renamed:    to_be_added.call(out, 'R'),
            copied:     to_be_added.call(out, 'C')
          },
          new_files: untracked.call(out)
        }
      end
    end  

    def clone(source, dest)
      git "clone", source, dest
      dest
    end

    def pull(branch=nil)
      git "pull", "#{branch.nil? ? 'origin'+branch : ''}"
    end

    def push(branch=nil)
      git "push", "#{branch.nil? ? 'origin'+branch : ''}"
    end

    def fetch
      git "fetch"
    end

    def correct?(repo_name)
      cloned = File.join @clone, repo_name
      puts "nothing to test"; return unless Dir.exist? cloned
      vob_pwd = File.join CONFETTI_HOME, AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name], vob
      ignored = @ignored + [".git/"]

      result_glob = Dir.glob("#{cloned}/**/*").map{|rg| rg.gsub("#{cloned}/", "")}
      source_glob = Dir.glob("#{vob_pwd}/**/*").map{|sg| sg.gsub("#{vob_pwd}/", "")}

      result_list = Rake::FileList.new(result_glob){|rg| ignored.each{|i| rg.exclude i}}
      source_list = Rake::FileList.new(source_glob){|sg| ignored.each{|i| sg.exclude i}}

      res = result_list == source_list
      if res
        puts "Repository is imported correctly".green.bold
      else
        puts "Repository is imported uncorrectly".red.bold
      end
      
      res
    end

    def current_branch
      in_repo{git("branch").detect{|br| br =~ /^\*/}.gsub(/^\*\s/, "")}
    end

  private

    def git(*params)
      command "git", params.join("\s")
    end

    def in_repo(&block)
      raise "No block given" unless block_given?
      current_dir = Dir.pwd 
      Dir.chdir File.join @git_folder, @vob
      res = yield
      Dir.chdir current_dir
      res
    end

    def file_to_add(file_name)
      File.join Dir.pwd, @vob_working_tree, file_name
    end

  end
end