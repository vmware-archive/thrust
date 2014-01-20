module Thrust::Executor
  def self.system_or_exit(cmd, output_file = nil)
    self.system(cmd, output_file) or raise '******** Build failed ********'
  end

  def self.system(cmd, output_file = nil)
    STDERR.puts "Executing #{cmd}"
    cmd += " > #{output_file}" if output_file
    Kernel::system(cmd)
  end

  def self.capture_output_from_system(cmd)
    captured_output = `#{cmd}`
    raise '******** Build failed ********' if $?.exitstatus > 0

    captured_output
  end

  def self.check_command_for_failure(cmd)
    STDERR.puts "Executing #{cmd} and checking for FAILURE"
    result = %x[#{cmd} 2>&1]
    STDERR.puts "Results:"
    STDERR.puts result

    result.include?("Finished") && !result.include?("FAILURE") && !result.include?("EXCEPTION")
  end
end
