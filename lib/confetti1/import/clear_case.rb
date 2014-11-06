module Confetti1
  module Import
    # se nbu
    # ct1 mkview -raw -name confetti-import_1
    # set v=m:\confetti-import_1
    # set g=--git-dir=%v%\nbu.meta\git --work-tree=%v%
    # ct setcs -tag confetti-import_1 r:\Mcu_Ngp\Versions_8.X\V8.3\8.3.0.11.8
    # git %g% init
    # pushd %v%
    # echo **/Release/bin >> %v%\nbu.meta\git\info\exclude\info\exclude
    # echo **/lost+found >> %v%\nbu.meta\git\info\exclude\info\exclude
    # git %g% add rvfc swInfra
    # git %g% commit -a -m "mcu_8.3.0.11.8"
    # git %g% tag -a mcu_8.3.0.11.8
    # md d:\gitest\mcu_8.3.0.11.8
    # pushd d:\gitest\mcu_8.3.0.11.8
    # git clone file://%v%/nbu.meta/git
    class ClearCase

      def initialize
        #FIXME I am ugly hardcoded, fix me, please
        # @view_name = "vtrofymyuk_view1"
        # @view_location = "M:"
        #------------------------------------------
        #@view_path = File.join @view_location, @view_name 
        #Dir.chdir @view_path 
      end

      def configspec
        out = command("ct", "catcs")
        
      end

      def configspec=(args)
        #ct edcs
      end

      def mkview
        out = command("ct1", "mkview", "-raw", "-name", @view_name)
      end

      def mount
        out = command("set", "v=#{@view_path}")
      end

    private

      def parse_configspec(path="#{Confetti1::Import.root}/test/test_store/mock_configspec")
        conf_spec = File.read(path)
        parsed_rows = conf_spec.split("\n").map do |cs| 
          cs.split.join(" ")
        end.reject{|cs| cs.empty?}
        parsed_costum = parsed_rows.map do |r|
          r.gsub(/\s+/, "\s").split("\s")
        end
        parsed_custom
      end

      def command(cmd, *argv)
        output = `#{cmd} #{argv.join(" ")}`
        output.split("\n")
      end 

    end
  end
end