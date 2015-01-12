module Confetti1
  module Import
    module Brsource
      def branch(label=nil)
        vroot = `cleartool pwv -root`.strip!

        root_ver = "configspec.txt@@\\main\\0"

        dest_lb = label
        dest_lb = mcu_label_from_cspec(`cleartool catcs`, "current configspec") if !dest_lb
        return if !dest_lb

        Dir.chdir "#{vroot}/mcu"
        dest_ver = `cleartool find configspec.txt -version "lbtype(#{dest_lb})" -print`.strip!
        dest_ver =~ /\\([^\\]+)\\(\d+)$/
        dest_br = $1

        puts "from label #{dest_lb} on branch #{dest_br}"

        while true do
          dest_ver =~ /(.*)\\\d+$/
          dest_ver_base = $1
          dest_head_ver = dest_ver_base + "\\0"
          if dest_head_ver == root_ver
            puts "reached root."
            return
          end

          merge_flag = false
          pred = desc_param(`cleartool describe -l #{dest_head_ver}`, /predecessor version: (.*)/)
          pred = "configspec.txt@@" + pred if pred != nil
          if !pred || pred == root_ver
            dest_head_ver = dest_ver_base + "\\1"
            pred = desc_param(`cleartool describe -l #{dest_head_ver}`, /Merge@.* <- (.*)/)
            if pred == nil
              puts "reached root."
              return
            end
            merge_flag = true
          end
          src_ver = pred
          src_ver =~ /\\([^\\]+)\\(\d+)$/
          src_br = $1
          src_lb = mcu_label_from_cspec(File.read(src_ver), "version #{src_ver}")
          return if !src_lb

          puts "to label #{src_lb} on branch #{src_br}" + (merge_flag ? " (*)" : "")

          dest_ver = src_ver
          dest_lb = src_lb
          dest_br = src_br
        end
      end
    private
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
            puts cspec
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

    end
  end
end
