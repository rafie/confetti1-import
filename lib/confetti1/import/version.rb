
module Confetti
module Import

class Version

	def initialize(product, version, tag)
		@product = product
		@version = version
		@tag = tag
	end

	def make_commit(repo, type, testing)
		git = Git.new(path: repo)
		unless origin_tag.nil?
			raise ArgumentError.new("Tag '#{origin_tag}' not found in repository") if ! git.tag_exist?(origin_tag)
			git.checkout!(origin_tag)
		end
		ignored = YAML.load_file(File.join(ConfettiEnv.output_path, 'ignored.yml'))
		git.checkout!(branch, '-b') unless git.branch_exist?(branch)
		git.append_exclude(ignored)
		files_map = YAML.load_file(File.join(ConfettiEnv.output_path, "#{type}.yml"))
		git.exclusive_commit(files_map.concat(ignored))
		testing_files = YAML.load_file(File.join(ConfettiEnv.output_path, "#{testing}.yml"))
		if git.correct?(testing_files, branch)
			git.tag(tag) if tag
		end
	end

    def commit(cs_location, tag = nil, branch = 'master', origin_tag = nil)

      clear_case = ClearCase.new
      clear_case.configspec = cs_location
      clear_case.scan_to_yaml

      make_commit(ConfettiEnv.small_reposiroty, 'big', 'small')
      make_commit(ConfettiEnv.big_repository, 'small', 'bit') if ConfettiEnv.handle_big
    end

end # class Version

end # module Import
end # module Confetti
