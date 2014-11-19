require 'test_helper'
include TestHelper
class TestConfetti1ImportGit < Minitest::Test

  def test_init
    setup
    vob = "vob1"
  
    result = @git.init! vob
    assert Dir.exist?(File.join(@test_git_repo, vob)), "Should be created GIT folder for VOB files" 
    assert_equal result, File.join(@test_git_repo, vob, ".git"), "GIT repository should be initialized"
    result = @git.init! vob
    Dir.chdir File.join(@test_git_repo)
    assert_equal 1,  Dir["*"].length
    teardown
  end

  def test_exclude
    setup
    vob = "vob2"
    dot_path = @git.init! vob
    ignore_list = Confetti1Import::AppConfig.ignore_list

    @git.exclude!
    assert_equal File.read(File.join(dot_path, "info", "exclude")).split("\n"), ignore_list
    teardown
  end

  def test_commit_a

  end

  def test_status
    # TODO: dummy:)
  end

private

  def setup
    @current_path = Dir.getwd
    @test_git_repo = File.join("test_store", "git_repo")
    @git = Confetti1Import::Git.new
    @git.instance_variable_set(:@git_folder, @test_git_repo)
  end

  def teardown
    Dir.chdir @current_path
    FileUtils.rm_rf @test_git_repo
  end

end