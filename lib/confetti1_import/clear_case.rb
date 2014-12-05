module Confetti1Import
  class ClearCase < Base

    def initialize
      @view_name =  AppConfig.clear_case[:view_name]
      @view_location =  AppConfig.clear_case[:view_location]
      @view_path = File.join @view_location, @view_name  

      #FIXME: Should be deteled on real configspec
      #@tmp_configspec = File.read(File.join(@view_location, @view_name, "configspec"))
    end

    def configspec
      out=""
      in_cs{out = ct "catcs"}
      #FIXME: Some stub
      #out = @tmp_configspec 
      parse_configspec out
    end

    def configspec=(cs_file)
      out = ""
      in_cs{out = ct("setcs", cs_file)}
      raise out if out =~ /^cleartool\:\sError\:/
    end

    def mkview
      out = ct "mkview -raw -name", @view_name
    end

    def mount
      out = command("set", "v=#{@view_path}")
    end

    def mount(vob_tag="--all")
      ct "mount", vob_tag
    end

  private

    def ct(*params)
      command "ct", params.join("\s")
    end

    def parse_configspec(conf_spec)
      clean = conf_spec.map{|cs| cs.gsub(/\s+/, " ")}.reject{|cs|cs.size < 2}
      preparsed = clean.map{|cs| cs.split("\s")}
      preparsed.shift
      preparsed.map do |pp|
        {vob: pp[1].gsub(/(\.){3}|\//,""), version: pp[2]}
      end
    end

    def in_cs(&block)
      raise "No block given" unless block_given?
      current_dir = Dir.pwd 
      Dir.chdir File.expand_path File.join @view_path
      res = yield
      Dir.chdir current_dir
      res
    end

  end
end