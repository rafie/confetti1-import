require 'test_helper'
class Confetti1ImportCLITest < Minitest::Test
  include TestHelper 
  def test_init
    Confetti1::Import::CLI.init([STORAGE_PATH, "test_cobfetti1"])
    dst = Dir.glob(File.join(STORAGE_PATH, "test_cobfetti1", "**", "*")) 
    src = Dir.glob(File.join(GEM_ROOT, "confetti_import" "**", "*"))
    assert (dst-src) == [], "Folders should be equal:\n #{dst},\n #{src} " 
    FileUtils.rm_rf(File.join(STORAGE_PATH, )) 
  end
end