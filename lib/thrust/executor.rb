module Thrust::Executor
  def self.system_or_exit(cmd, stdout = nil)
    self.system(cmd, stdout) or raise '******** Build failed ********'
  end

  def self.system(cmd, stdout = nil)
    STDERR.puts "Executing #{cmd}"
    cmd += " >#{stdout}" if stdout
    Kernel::system(cmd)
  end
end
