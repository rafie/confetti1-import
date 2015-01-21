module Confetti1
  module Import
    class ClearCase < Base

      def initialize
        @view_path = ConfettiEnv.view_path 
      end

      def scan_to_yaml
        big_files = []
        small_files = []
        ignored = []

        current_dir = ConfettiEnv.home
        ignore_list = ConfettiEnv.ignore_list

        configspec = self.configspec

        configspec.each do |cs|
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
              small_files << vob_entry
            else
              big_files  << vob_entry
            end

          end
        end

        File.open(File.join(ConfettiEnv.output_path, 'small.yml'), 'w'){|f| f.write(small_files.to_yaml)}
        File.open(File.join(ConfettiEnv.output_path, 'big.yml'), 'w'){|f| f.write(big_files.to_yaml)}
        File.open(File.join(ConfettiEnv.output_path, 'ignored.yml'), 'w'){|f| f.write(ignored.to_yaml)}
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

      def originate(cs_path)
        self.configspec = cs_path
        origin = ""
        self.inside_view do
          origin = branch_source
        end
        origin
      end

    private

      def branch_source(label=nil)
        vroot = cleartool("pwv -root").strip!

        root_ver = "configspec.txt@@\\main\\0"

        dest_lb = label
        dest_lb = mcu_label_from_cspec(cleartool("catcs"), "current configspec") if !dest_lb
        return if !dest_lb

        Dir.chdir "#{vroot}/mcu"
        dest_ver = cleartool("find configspec.txt -version \"lbtype(#{dest_lb})\" -print").strip!
        dest_ver =~ /\\([^\\]+)\\(\d+)$/
        dest_br = $1
        out = "from label #{dest_lb} on branch #{dest_br}\n"

        while true do
          dest_ver =~ /(.*)\\\d+$/
          dest_ver_base = $1
          dest_head_ver = dest_ver_base + "\\0"
          if dest_head_ver == root_ver
            out << "reached root.\n"
            break
          end

          merge_flag = false
          pred = desc_param(cleartool("describe -l #{dest_head_ver}"), /predecessor version: (.*)/)
          pred = "configspec.txt@@" + pred if pred != nil
          if !pred || pred == root_ver
            dest_head_ver = dest_ver_base + "\\1"
            pred = desc_param(cleartool("describe -l #{dest_head_ver}"), /Merge@.* <- (.*)/)
            if pred == nil
              out << "reached root.\n"
              break
            end
            merge_flag = true
          end
          src_ver = pred
          src_ver =~ /\\([^\\]+)\\(\d+)$/
          src_br = $1
          src_lb = mcu_label_from_cspec(File.read(src_ver), "version #{src_ver}")
          break if !src_lb
          out << "to label #{src_lb} on branch #{src_br}" + (merge_flag ? " (*)\n" : "\n")
          dest_ver = src_ver
          dest_lb = src_lb
          dest_br = src_br
        end
        out
      end

      def parse_configspec(conf_spec)
        splited = conf_spec.map{|cs|cs.split("\s")}.reject{|cs| cs.empty? or cs.size < 4 or cs.detect{|ccs| ccs=~/^#/}}
        splited.map do |cs| 
          vob_name = cs[1].to_s[/\w{2,}/]
          {
            vob: vob_name, 
            version: cs[2],
            path: File.join(@view_path, vob_name)
          } 
        end
      end

      def mcu_label_from_cspec(cspec, context)
        cspec = cspec.lines
        mcu = cspec.grep(/[\\\/]mcu[\\\/]/i)
        if mcu.empty?
          # element * label
          mcu = cspec.grep(/\*/)
          if mcu.empty?
            puts "label *unknown* in #{context}"
            puts "check configspec:"
            puts
            Logger.log cspec
            return nil
          end
          # mcu[0] is probably element * CHECKEDOUT
          return mcu[1].split(/\s+/)[2]
        end
        
        # element /mcu/... label
        mcu[0].split(/\s+/)[2]
      end

      def desc_param(desc, regexp)
        desc = desc.lines
        param = desc.grep(regexp)[0]
        return nil if !param
        param =~ regexp
        $1
      end

      def ct(*params)
        raise ArgumentError.new("Cleartool arguments are nil or empty") if params.compact.empty?
        command("ct", params.join("\s"))
      end

      def cleartool(*params)
        raise ArgumentError.new("Cleartool arguments are nil or empty") if params.compact.empty?
        raw_command "cleartool", params.join("\s")
      end
    end
  end
end
