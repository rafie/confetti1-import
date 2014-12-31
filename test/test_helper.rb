require 'minitest/test'
require 'minitest/autorun'
require 'minitest/mock'
require 'fileutils'
require 'confetti1/import'

module TestHelper
  STORAGE_PATH = File.join File.dirname(__FILE__), "test_store"
end