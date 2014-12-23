module Confetti1Import
  class ClearCase < Base

    def initialize
      @view_name =  AppConfig.clear_case[:view_name]
      @view_location =  AppConfig.clear_case[:view_location]
      @view_path = File.join @view_location, @view_name  

      #FIXME: Should be deteled on real configspec
      #@tmp_configspec = File.read(File.join(@view_location, @view_name, "configspec"))
    end

    def configspec(parse_file=nil)
      out=""
      if parse_file
        out = File.read(parse_file).split("\n")
      else
        in_directory(@view_path){out = ct "catcs"}
      end
      parse_configspec out
    end

    def configspec=(cs_file)
      out = ""
      in_directory(@view_path){out = ct("setcs", cs_file)}
      raise out if out =~ /^cleartool\:\sError\:/
    end

    def mount
      out = command("set", "v=#{@view_path}")
    end

    def mount(vob_tag="--all")
      ct "mount", vob_tag
    end

  private

    def parse_configspec(conf_spec)
      splited = conf_spec.map{|cs|cs.split("\s")}.reject{|cs| cs.empty? or cs.size < 4 or cs.detect{|ccs| ccs=~/^#/}}
      splited.map do |cs| 
        vob_name = cs[1].to_s[/\w{3,}/]
        {
          vob: vob_name, 
          version: cs[2],
          path: File.join(@view_path, vob_name)
        } 
      end
    end

    def ct(*params)
      command "ct", params.join("\s")
    end
  end
end