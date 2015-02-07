
module Confetti
module Import

class ProductVersions

	def initialize
		versions_config = YAML.load_file(File.join(ConfettiEnv.home, 'config', 'versions.yml'))
		forest_location = File.expand_path(File.join(ConfettiEnv.home, "versions"))
		wrong_locations = []
		wrong_formats   = []
		Dir.glob(File.join(forest_location, "**")).each{ |fl| FileUtils.rm_rf(fl) }
		current_wd = Dir.getwd
		clear_case = ClearCase.new
		versions_config.each_pair do |int_branch, locations|
			puts "-> for #{int_branch}"
			int_branch_location = File.join(forest_location, int_branch.downcase)

			Dir.mkdir(int_branch_location) unless Dir.exist?(int_branch_location)
			File.open(File.join(int_branch_location, 'dir'), 'w') { |f|f.write(int_branch_location) }

			locations.each do |location|
				begin
					Dir.chdir location
				rescue Errno::ENOENT => e
					Logger.log e.message.to_s.red
					wrong_locations << location
					next
				end

				Dir.glob(File.join('**', 'configspec.txt')).each do |cs_location|
					begin
			  			splited_location = cs_location.split(/(\\)|\//)
			  			cs_index = splited_location.rindex{|sl|sl=~ /configspec.txt/i}
			  			unless cs_index
							puts "Wrong location: '#{cs_location}'".red.bold
							wrong_locations << cs_location
							next
			  			end
			  			unless splited_location[cs_index-1] =~ /^((\d+\.)+)(\d+)$/
							puts "Version location has wrong format: #{splited_location}".yellow.bold
							wrong_formats << cs_location
							next
			  			end

				  		db_version_place = File.join(int_branch_location, splited_location[cs_index-1])
				  		Dir.mkdir(db_version_place) unless Dir.exist?(db_version_place)
				  		FileUtils.cp(cs_location, File.join(db_version_place, 'configspec.txt'))

					rescue Exception => e
			  			puts "#{e.class}: #{e.message}".red.bold
			  			next
					end

					unless File.exist?(File.join(int_branch_location, 'int_branch.txt'))
						begin
							origin = clear_case.originate(File.join(db_version_place, 'configspec.txt'))
							File.open(File.join(int_branch_location, 'origin.txt'), 'w') { |f| f.write(origin) }
						rescue Exception => e
							Logger.log e.class
							Logger.log e.message
					  	end
	
					File.open(File.join(int_branch_location, 'int_branch.txt'), 'w'){|f| f.write("#{int_branch}_int_br")}
				end
			end
		end
	end

		Dir.chdir current_wd
		puts "Cleaning up.."
		
		Dir.glob(File.join(ConfettiEnv.versions_path, '**')).each do |version|
			next unless File.directory? version
			if Dir.glob("#{version}/**/").size <= 1
				puts " --> #{version} has no labels and will be removed".red
				puts "--------------------------------------------------------"
				Logger.log Dir.glob(File.join(version, "**", "*")).join("\n")
				puts "--------------------------------------------------------"
				FileUtils.rm_rf(version)
			end
		end
		
		File.open(File.join(ConfettiEnv.log_path, 'wrong_locations.txt'), 'w'){|f|f.write(wrong_locations.join("\n"))}
		File.open(File.join(ConfettiEnv.log_path, 'wrong_formats.txt'), 'w'){|f|f.write(wrong_formats.join("\n"))}
		end
	
	end

end # class ProductVersions

end # module Import
end # module Confetti
