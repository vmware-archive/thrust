module Thrust::Executor
  def self.system_or_exit(cmd, output_file = nil)
    self.system(cmd, output_file) or raise '******** Build failed ********'
  end

  def self.system(cmd, output_file = nil)
    STDERR.puts "Executing #{cmd}"
    cmd += " >#{output_file}" if output_file
    Kernel::system(cmd)
  end

  def self.capture_output_from_system(cmd)
    captured_output = `#{cmd}`
    raise '******** Build failed ********' if $?.exitstatus > 0

    captured_output
  end
end
