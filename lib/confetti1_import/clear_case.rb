module Confetti1Import
  class ClearCase < Base

    def initialize
      #FIXME I am ugly hardcoded, fix me, please
      @view_name =  AppConfig.clear_case[:view_name]
      @view_location =  AppConfig.clear_case[:view_location]
      @view_path = File.join @view_location, @view_name  

      #FIXME: Should be deteled on real configspec
      @tmp_configspec = File.read(File.join(@view_location, @view_name, "configspec"))
    end

    def configspec
      #out = command("ct", "catcs")
      #FIXME: Some stub
      out = @tmp_configspec 
      parse_configspec out
    end

    def configspec=(cs_file)
      command "ct", "edcs", cs_file
    end

    def mkview
      #out = command("mkview", "-raw", "-name", @view_name)
    end

    def mount
      #out = command("set", "v=#{@view_path}")
    end

    def self.find_versions
      
    end

  private

    def parse_configspec(conf_spec)
      clean = conf_spec.split("\n").map{|cs| cs.gsub(/\s+/, " ")}.reject{|cs|cs.size < 2}
      preparsed = clean.map{|cs| cs.split("\s")}
      preparsed.shift
      preparsed.map do |pp|
        {vob: pp[1].gsub(/(\.){3}|\//,""), version: pp[2]}
      end
    end

  end
end