module Thrust
  class Executor
    CommandFailed = Class.new(StandardError)

    def system_or_exit(cmd, output_file = nil)
      system(cmd, output_file) or raise(CommandFailed, '******** Build failed ********')
    end

    def system(cmd, output_file = nil)
      STDERR.puts "Executing #{cmd}"
      cmd += " > #{output_file}" if output_file
      Kernel::system(cmd)
    end

    def capture_output_from_system(cmd)
      captured_output = `#{cmd}`

      raise(CommandFailed, '******** Build failed ********') if $?.exitstatus > 0

      captured_output
    end

    def check_command_for_failure(cmd)
      STDERR.puts "Executing #{cmd} and checking for FAILURE"
      result = %x[#{cmd} 2>&1]
      STDERR.puts "Results:"
      STDERR.puts result

      result.include?("Finished") && !result.include?("FAILURE") && !result.include?("EXCEPTION")
    end
  end
end
