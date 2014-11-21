
require 'fileutils'

# class Pathname
# 	def /(x)
# 		self + x
# 	end
# end

dir = File.read('dir')
File.open("versions").readlines.each do |ver|
	ver.strip!
	FileUtils.mkdir(ver) unless File.directory?(ver)
	FileUtils.cp("#{dir}/#{ver}/configspec.txt", ver)
end
