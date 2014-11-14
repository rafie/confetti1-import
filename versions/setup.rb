
require 'FileUtils'

class Pathname
	def /(x)
		self + x
	end
end

dir = Pathname.new(File.read('dir'))
File.open("versions").readlines.each do |ver|
	ver.strip!
	FileUtils.mkdir(ver) if !File.directory?(ver)
	FileUtils.cp(dir/ver/"configspec.txt", ver)
end
