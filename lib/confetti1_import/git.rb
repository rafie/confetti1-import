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
        command("git", "--git-dir=#{@git_vob_dot_folder}", "--work-tree=#{@vob_working_tree}", "init")
      else
        puts "GIT repository #{@git_folder} already initialized in #{@git_vob_dot_folder}"
      end
      @git_folder
    end

    def exclude!
      puts "Excluding not needed files: #{@ignored.inspect}"
      File.open(File.join(@git_vob_dot_folder, 'info', 'exclude'), 'w') do |f|
        f << @ignored.join("\n")
      end
    end

    def add_file(file)
      puts "Added file #{file_to_add(file)}"
      command "git", "add", file_to_add(file)
    end

    def commit_a!(message="Confetti commit")
      # self.status[:new_files].each do |file|
      #   self.add_file(file)
      # end
      current_dir = Dir.pwd 
      Dir.chdir File.join @git_folder, @vob 
      command "git", "add ."
      command "git", "commit", "-a ", "-m\"#{message}\""
      Dir.chdir current_dir
    end

    def status
      current_dir = Dir.pwd 
      Dir.chdir File.join @git_folder, @vob 
      select_files = Proc.new do |files, mask| 
        files.select{|o| o =~ mask}.map{|o| o.gsub(mask, '')}
      end

      to_be_commited = lambda{|git_files, mode| select_files.call(git_files, /#{mode}\s\s/)}
      to_be_added = lambda{|git_files, mode| select_files.call(git_files, /\s#{mode}\s/)}
      untracked = lambda{|git_files| select_files.call(git_files, /\?\?\s/)}
      
      out = command "git", "status", "--porcelain"
      Dir.chdir current_dir
      {
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

  private

    def file_to_add(file_name)
      File.join Dir.pwd, @vob_working_tree, file_name
    end

  end
end