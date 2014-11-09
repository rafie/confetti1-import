module Confetti1
  module Import
    class ClearCase < Base

      def initialize
        #FIXME I am ugly hardcoded, fix me, please
        @view_name = confetti_config["clear_case"]["view"]["name"]
        @view_location = confetti_config["clear_case"]["view"]["location"]
        @view_path = File.join @view_location, @view_name  
      end

      def configspec
        out = command("ct", "catcs")
        parse_configspec out
      end

      def configspec=(args)
        #ct edcs
      end

      def mkview
        out = command("mkview", "-raw", "-name", @view_name)
      end

      def mount
        out = command("set", "v=#{@view_path}")
      end

    private

      def parse_configspec(path="#{Confetti1::Import.root}/test/test_store/mock_configspec")
        conf_spec = File.read(path)
        clean = conf_spec.split("\n").map{|cs| cs.gsub(/\s+/, " ")}.reject{|cs|cs.size < 2}
        preparsed = clean.map{|cs| cs.split("\s")}
        preparsed.shift
        preparsed.map do |pp|
          {vob: pp[1].gsub(/(\.){3}|\//,""), version: pp[2]}
        end
      end

    end
  end
end