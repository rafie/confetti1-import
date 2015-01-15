$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require 'confetti1/import'
Confetti1::Import.main(ARGV)