def mcu_label_from_cspec(cspec)
	cspec = cspec.lines
	mcu = cspec.grep(/[\\\/]mcu[\\\/]/i)
	if mcu.empty?
		puts "label *unknown* on branch #{src_br}"
		puts "check configspec:"
		puts
		puts cspec
		return nil
	end
	
	# element /mcu/... label
	mcu[0].split(/\s+/)[2]
end

def desc_param(desc, regexp)
	desc = desc.lines
	param = desc.grep(regexp)[0]
	return nil if !param
	param =~ regexp
	$1
end

vroot = `cleartool pwv -root`.strip!

root_ver = "configspec.txt@@\\main\\0"

dest_lb = ARGV.shift
dest_lb = mcu_label_from_cspec(`cleartool catcs`) if !dest_lb
exit if !dest_lb

Dir.chdir "#{vroot}/mcu"
dest_ver = `cleartool find configspec.txt -version "lbtype(#{dest_lb})" -print`.strip!
dest_ver =~ /\\([^\\]+)\\(\d+)$/
dest_br = $1

puts "from label #{dest_lb} on branch #{dest_br}"

while true do
	dest_ver =~ /(.*)\\\d+$/
	dest_ver_base = $1
	dest_head_ver = dest_ver_base + "\\0"
	if dest_head_ver == root_ver
		puts "reached root."
		exit
	end

	pred = desc_param(`cleartool describe -l #{dest_head_ver}`, /predecessor version: (.*)/)
	
	pred = "configspec.txt@@" + pred if pred != nil
	if !pred || pred == root_ver
		dest_head_ver = dest_ver_base + "\\1"
		pred = desc_param(`cleartool describe -l #{dest_head_ver}`, /Merge@.* <- (.*)/)
		if pred == nil
			puts "reached root."
			exit
		end
	end
	src_ver = pred
	src_ver =~ /\\([^\\]+)\\(\d+)$/
	src_br = $1
	src_lb = mcu_label_from_cspec(File.read(src_ver))

	puts "to label #{src_lb} on branch #{src_br}"

	dest_ver = src_ver
	dest_lb = src_lb
	dest_br = src_br
end
