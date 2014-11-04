require 'minitest/autorun'
require 'confetti1/import'
require 'fileutils'
module TestHelper
  STORAGE_PATH = File.join File.dirname(__FILE__), "test_store"
  GEM_ROOT = File.dirname(__FILE__)
end