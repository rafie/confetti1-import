module Confetti1Import
  class Git < Base

    def initialize
      @git_folder = AppConfig.git[:path]
      @view_root = File.join(AppConfig.clear_case[:view_location], AppConfig.clear_case[:view_name])
      @ignored = AppConfig.ignore_list
    end

    def init!(vob)
      @vob = vob
      @vob_working_tree = File.join @view_root, @vob
      @git_vob_dot_folder = File.join @git_folder , @vob, ".git"
      unless Dir.exist? @git_vob_dot_folder
        puts "Initializing GIT repository for '#{vob}' in #{@git_vob_dot_folder}"
        FileUtils.makedirs @git_vob_dot_folder
        git "--git-dir=#{@git_vob_dot_folder} --work-tree=#{@vob_working_tree}", "init"
        in_repo{git 'commit --allow-empty -m"initial commit"'}
      else
        puts "GIT repository #{@git_folder} already initialized in #{@git_vob_dot_folder}"
      end
      @git_vob_dot_folder
    end

    def exclude!
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
      puts "================================> #{branch_name}"
      in_repo{git "branch", branch_name}
      # args = args.flatten 
      # fails "args are empty" if args.nil?
      # in_repo do
      #   puts "Enter some information about GIT branch you want to create"; return if args.empty?
      #   puts "Enter mode ('-a', '-d')"; return if args[:mode].is_a?(Symbol) and (![:a, :d].includes?(args[:mode]))
      #   git_branch = lambda{|*args| git "branch", args[:apply_mode], args[:branch_name]}
      #   if args[:mode] == :a
      #     git_branch.call({apply_mode: "-a"})
      #   elsif args[:mode] == :d
      #     git_branch.call({apply_mode: "-d"})
      #   elsif !args[:name].empty? and args[:mode].empty?
      #     git_branch.call({branch_name: name})
      #   else
      #     puts "Oops, seems to be we have missed something"
      #   end
      # end
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

    def self.clone(source, dest)
      git "clone", source, dest
      dest
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