
require 'FileUtils'
require 'byebug'

# byebug
dirs = {}
dirs_text = File.read('dirs')
dirs_text.split("\n").each do |dir_text|
	x = dir_text.split("\t")
	dirs[x[0]] = x[1].split(" ")
end

Dir.foreach('.') do |d|
	next if d == '.' || d == '..'
	next if !Dir.exist?(d)
#	puts d
	Dir.chdir(d) do

		puts d + ": " + dirs[d].join(" ")
		File.write('dirs', dirs[d].join("\n"))
#		FileUtils.mv('dir', 'dirs') rescue ''
#		if File.exist?('origin.txt')
#			FileUtils.mv('origin.txt', 'origin')
#		else
#			File.write('origin', '')
#		end
#		if File.exist?('int_branch.txt')
#			FileUtils.mv('int_branch.txt', 'int_branch')
#		else
#			File.write('int_branch', '')
#		end

	end
end
