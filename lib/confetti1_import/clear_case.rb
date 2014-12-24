module Confetti1Import
  class ClearCase < Base

    def initialize
      @view_path = ConfettiEnv.view_path 
    end

    def scan
      big_files = []
      small_files = []
      ignored = []
      current_dir = Dir.getwd
      ignore_list = AppConfig.ignore_list
      Dir.glob(File.join(@view_path, '**', '*')).each do |view_entry|

        unless ignore_list.select{|il| File.fnmatch(File.join(@view_path, il), view_entry)}.empty?
          ignored << view_entry
          next
        end

        if File.size(view_entry) > AppConfig.git[:ignore_size]
          small_files << view_entry
        else
          big_files << view_entry
        end

      end
      File.open(File.join(CONFETTI_HOME, 'config', 'small.txt'), 'w'){|f| f.write(small_files.join("\n"))}
      File.open(File.join(CONFETTI_HOME, 'config', 'big.txt'), 'w'){|f| f.write(big_files.join("\n"))}
      File.open(File.join(CONFETTI_HOME, 'config', 'ignored.txt'), 'w'){|f| f.write(ignored.join("\n"))}
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