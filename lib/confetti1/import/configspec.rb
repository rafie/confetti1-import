module Confetti1
  module Import
    class ConfigSpec

		@@vobs_arr
		def initialize(cspecfile)
			out = File.read(cspecfile).split("element /")
			@@vobs_arr = Array.new(out.length)
			out.shift
			out.each_with_index {|val, index| @@vobs_arr[index]=val.squeeze(" ").split(" ")[1] }
			@@vobs_arr.reject!(&:nil?).reject!(&:empty?)
			
		end
		
		def vobs
			@@vobs_arr
		end
    end
  end
end