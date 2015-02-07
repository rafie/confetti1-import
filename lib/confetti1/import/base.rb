module Confetti

module Import

class Base

  def in_directory(dir_to_run, &block)
    raise "No block given" unless block_given?
    current_dir = Dir.pwd 
    Dir.chdir dir_to_run
    res = yield
    Dir.chdir current_dir
    res
  end

  def raw_command(cmd, *argv)
    cmd = "#{cmd} #{argv.join("\s")}"
    Logger.log "#{'Running command:'} #{cmd}"
    output = ""
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      exit_status = wait_thr.value
      if exit_status.success?
        output = stdout.read 
      else
        Logger.log stdout.read
        Logger.log stderr.read
        raise stderr.read
      end
    end
    #puts "output: #{output}"
    output
  end

  def command(cmd, *argv)
    raw_command(cmd, argv).split("\n")
  end
  
end

end
end
