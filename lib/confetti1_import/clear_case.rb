module Confetti1Import
  class ClearCase < Base
    require_relative "brsource"
    include Confetti1Import::Brsource

    def initialize
      @view_path = ConfettiEnv.view_path 
    end

    def scan
      big_files = []
      small_files = []
      ignored = []
      current_dir = Dir.getwd
      ignore_list = ConfettiEnv.ignore_list
      puts "Scanning view ----> #{@view_path}"
      Dir.glob(File.join(@view_path, '**', '*')).each do |view_entry|
        next if File.directory?(view_entry)
        unless File.exist?(view_entry)
          puts "File #{view_entry} is not found".red.bold
          next
        end
        unless ignore_list.select{|il| File.fnmatch(File.join(@view_path, il), view_entry)}.empty?
          ignored << view_entry
          next
        end
        if File.size(view_entry) < ConfettiEnv.exclude_size
          small_files << view_entry
        else
          big_files << view_entry
        end

      end
      puts "WARNING: #{ignored.size} files will be ignored:"
      ignored.each{|i|print "#{i},\s"}
      puts
      File.open(File.join(ConfettiEnv.home, 'config', 'small.txt'), 'w'){|f| f.write(small_files.join("\n"))}
      File.open(File.join(ConfettiEnv.home, 'config', 'big.txt'), 'w'){|f| f.write(big_files.join("\n"))}
      File.open(File.join(ConfettiEnv.home, 'config', 'ignored.txt'), 'w'){|f| f.write(ignored.join("\n"))}
      {ignored: ignored, big_files: big_files, small_files: small_files}
    end

    def scan_to_yaml
      big_files = {}
      small_files = {}
      ignored = []

      current_dir = ConfettiEnv.home
      ignore_list = ConfettiEnv.ignore_list

      configspec = self.configspec

      configspec.each do |cs|
        current_version = "#{rand(10000)}_vob_#{cs[:vob]}_#{cs[:version]}"
        big_vob_files = []
        small_vob_files = []

        Dir.glob(File.join(cs[:path], '**', '*')).each do |vob_entry|
          next if File.directory?(vob_entry)

          unless File.exist?(vob_entry)
            puts "File #{vob_entry} is not found".red.bold
            next
          end

          unless ignore_list.select{|il| File.fnmatch(File.join(@view_path, il), vob_entry)}.empty?
            ignored << vob_entry
            next
          end

          if File.size(vob_entry) < ConfettiEnv.exclude_size
            small_vob_files << vob_entry
          else
            big_vob_files << vob_entry
          end

        end #globb
        big_files.merge!(current_version => big_vob_files) unless big_vob_files.empty?
        small_files.merge!(current_version => small_vob_files) unless small_vob_files.empty?
      end# configspec

      File.open(File.join(ConfettiEnv.home, 'config', 'small.yml'), 'w'){|f| f.write(small_files.to_yaml)}
      File.open(File.join(ConfettiEnv.home, 'config', 'big.yml'), 'w'){|f| f.write(big_files.to_yaml)}
      File.open(File.join(ConfettiEnv.home, 'config', 'ignored.yml'), 'w'){|f| f.write(ignored.to_yaml)}
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

    def inside_view(*params, &block)
      raise 'No block given' unless block_given?
      in_directory(@view_path) do
        yield
      end
    end

    def originate(cs_path, label)
      self.configspec = cs_path
      origin = ""
      self.inside_view do
        origin = `ruby #{ConfettiEnv.home}/brsource.rb mcu_#{label}`
        puts origin
      end
      origin
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