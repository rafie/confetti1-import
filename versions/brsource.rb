
vroot = `cleartool pwv -root`.strip!

root_ver = "configspec.txt@@\\main\\0"

dest_lb = ARGV.shift
dest_lb = `cleartool catcs`.lines.grep(/[\\\/]mcu[\\\/]/i)[0].split(/\s+/)[2] if !dest_lb

Dir.chdir "#{vroot}/mcu"
dest_ver = `cleartool find configspec.txt -version "lbtype(#{dest_lb})" -print`.strip!
dest_ver =~ /\\([^\\]+)\\(\d+)$/
dest_br = $1

puts "from label #{dest_lb} on branch #{dest_br}"

while true do
	dest_ver =~ /(.*)\\\d+$/
	dest_head_ver = $1 + "\\0"
	if dest_head_ver == root_ver
		puts "reached root."
		exit
	end
	desc = `cleartool describe -l #{dest_head_ver}`.lines.grep(/predecessor version:/)[0]
	if desc == nil
		puts "reached root."
		exit
	end
	desc =~ /predecessor version: (.*)/
	src_ver = $1
	src_ver = "configspec.txt@@#{src_ver}"
	if src_ver == root_ver
		puts "reached root."
		exit
	end
	src_ver =~ /\\([^\\]+)\\(\d+)$/
	src_br = $1
	cspec = File.read(src_ver).lines
	mcu = cspec.grep(/[\\\/]mcu[\\\/]/i)
	if mcu.empty?
		puts "label *unknown* on branch #{src_br}"
		puts "check configspec:"
		puts
		puts cspec
		exit
	end
	mcu = mcu[0].split(/\s+/)
	src_lb = mcu[2]

	puts "to label #{src_lb} on branch #{src_br}"

	dest_ver = src_ver
	dest_lb = src_lb
	dest_br = src_br
end
