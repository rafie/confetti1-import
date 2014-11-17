require 'minitest/test'
require 'minitest/autorun'
require 'fileutils'
require_relative File.join('..', 'lib', 'confetti1_import')
module TestHelper
  STORAGE_PATH = File.join File.dirname(__FILE__), "test_store"
end