require 'minitest/spec'
require 'minitest/autorun'
require 'test_helper'
include TestHelper

module Confetti1
  module Import
    describe Git do
      it "can be created with no arguments" do
        Array.new.must_be_instance_of Array
      end
    end
  end
end