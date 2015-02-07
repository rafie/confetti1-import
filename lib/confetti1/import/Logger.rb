
module Confetti
module Import

class Logger

  def Logger.log(message = "")
    puts message
    return if ConfettiEnv.silent_log
    File.open(File.join(ConfettiEnv.log_path, 'confetti.log'), 'a'){|f|f.puts "-------[#{Time.now}]---------\n#{message}"}
  end

end

end # module Import
end # Confetti

