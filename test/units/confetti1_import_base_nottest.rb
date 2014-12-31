require 'test_helper'
include TestHelper
class TestConfetti1Import < Minitest::Test
  def test_command
    current = Dir.getwd
    Dir.chdir STORAGE_PATH 
    test_cmd_path = File.join(STORAGE_PATH, "test_command")
    Dir.mkdir(File.join(test_cmd_path))
    Dir.mkdir(File.join(test_cmd_path, "one"))
    Dir.mkdir(File.join(test_cmd_path, "two"))
    base_class = Confetti1Import::Base.new
    result = base_class.command("ls", "-l")

    assert_equal 3, result.size
    assert_raises(Errno::ENOENT){base_class.command("asdf", "qwerty")}

    Dir.chdir current
    FileUtils.rm_rf test_cmd_path 
  end
end
