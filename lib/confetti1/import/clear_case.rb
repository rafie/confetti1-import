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
    class ClearCase < Base

      def initialize
        #FIXME I am ugly hardcoded, fix me, please
        @view_name = confetti_config[:clear_case][:view][:name]
        @view_location = confetti_config[:clear_case][:view][:disc]
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

      def vobs_list
        cs = parse_configspec

      end

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