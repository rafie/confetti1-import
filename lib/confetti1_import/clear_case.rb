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
      command "ct set", cs_file
    end

    def mkview
      out = command("mkview", "-raw", "-name", @view_name)
    end

    def mount
      out = command("set", "v=#{@view_path}")
    end

    def self.find_versions(vob)
      version_inpt = AppConfig.clear_case[:versions_input_folder]
      version_out = AppConfig.clear_case[:versions_outut_folder]
      input_map = []
      FileUtils.mkdir_p(version_out)
      Dir.glob("#{version_inpt}/**").each do |entry|
        entry_name = entry.split("/").last
        dir_path = File.read(File.join(entry, 'dir'))
        entry_clean_name = entry_name.split("-").first
        puts "------------------------------------ #{dir_path} #{Dir.exists?(dir_path) ? "Exists" : "Not exists"}"
        Dir.open(dir_path).entries.reject{|ee| !(ee =~ /(\d\.)+/)}.each do |cs_folder|
          source_cs = File.join(dir_path, cs_folder, 'configspec.txt')
          dst_cs = File.join(entry, cs_folder)
          FileUtils.mkdir_p dst_cs
          begin
            FileUtils.cp(source_cs, dst_cs)
          rescue Errno::ENOENT
            FileUtils.rm_rf dst_cs
            puts "File '#{source_cs}' was not found".red.bold
            next
          end
          File.open(File.join(entry, 'int_branch.txt'), 'w'){ |f| f << "#{entry_name}_int_br"}
          puts "Copied '#{source_cs}' to '#{dst_cs}'".green.bold
        end
      end
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