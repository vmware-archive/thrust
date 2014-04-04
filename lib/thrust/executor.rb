module Thrust
  class Executor
    CommandFailed = Class.new(StandardError)

    def initialize(out = STDERR, execution_helper = Thrust::ExecutionHelper.new)
      @execution_helper = execution_helper
      @out = out
    end

    def system_or_exit(cmd, output_file = nil)
      @out.puts "Executing #{cmd}"
      cmd += " > #{output_file}" if output_file

      unless @execution_helper.capture_status_from_command(cmd)
        raise(CommandFailed, '******** Build failed ********')
      end
    end

    def capture_output_from_system(cmd)
      captured_output = `#{cmd}`

      raise(CommandFailed, '******** Build failed ********') if $?.exitstatus > 0

      captured_output
    end

    def check_command_for_failure(cmd)
      @out.puts "Executing #{cmd} and checking for FAILURE"
      result = %x[#{cmd} 2>&1]
      @out.puts "Results:"
      @out.puts result

      result.include?("Finished") && !result.include?("FAILURE") && !result.include?("EXCEPTION")
    end
  end
end
