module Confetti1
  module Import
    module CLI 
      def self.init(path=nil, custome_name=nil)
        app_name="confetti_import"
        working_app_name = custome_name || app_name
        app_pwd = path || Dir.pwd
        if File.exist? File.join(app_pwd, app_name, "config", "confetti_config.yml")
          Logger.log "Confetti exists. Exiting."
          return
        end
        FileUtils.cp_r(File.join(Confetti1::Import.root, app_name), app_pwd)
      end 
    end
  end
end