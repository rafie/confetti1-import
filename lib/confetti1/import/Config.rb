
module Confetti
module Import

module Config

  @@home_dir = File.expand_path(File.join("..", "..", ".."), __FILE__)
  @@default_conf = YAML.load_file(File.join(@@home_dir, "config", "confetti_config.yml"))

  def home
    @@home_dir
  end

  def workspace
    File.join(@@home_dir, 'workspace')
  end

  def git_path
    ENV['GIT_PATH'] || @@default_conf['git_path']
  end

  def view_path
    ENV['VIEW_PATH'] || @@default_conf['view_path']
  end

  def exclude_size
    ENV['EXCLUDE_SIZE'] || @@default_conf['exclude_size']
  end

  def ignore_list
    @@default_conf['ignore_list']
  end

  def clone_path
    ENV['CLONE_PATH'] || File.join(@@home_dir, 'workspace', 'cloned')
  end

  def handle_big
    ENV['HANDLE_BIG']
  end

  def small_reposiroty
    File.join(self.git_path, 'small') || ENV['SMALL_REPOSITORY']
  end

  def big_repository
    File.join(self.git_path, 'big') || ENV['SMALL_REPOSITORY'] if handle_big
  end

  def git_repozitories
    [self.small_reposiroty, self.big_repository].compact
  end

  def versions_path
    ENV['VERSIONS_PATH'] || File.join(@@home_dir, 'versions')
  end

  def log_path
    File.join(@@home_dir, 'log')
  end

  def output_path
    File.join(@@home_dir, 'output')
  end

  def silent_log
    ENV['SILENT_LOG']
  end

end

end # module Import
end # Confetti
