$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require 'confetti1_import'
command = ARGV.shift
Confetti1::Import::CLI.new.send(command, ARGV)