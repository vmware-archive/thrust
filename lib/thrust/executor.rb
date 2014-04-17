module Thrust
  class Executor
    CommandFailed = Class.new(StandardError)

    def initialize(out = STDERR, execution_helper = Thrust::ExecutionHelper.new)
      @execution_helper = execution_helper
      @out = out
    end

    def system_or_exit(cmd, output_file = nil, env = {})
      @out.puts "Executing #{cmd}"
      cmd += " > #{output_file}" if output_file

      unless @execution_helper.capture_status_from_command(cmd, env)
        raise(CommandFailed, '******** Build failed ********')
      end
    end

    def system(cmd, output_file = nil)
      @out.puts "Executing #{cmd}"
      cmd += " > #{output_file}" if output_file

      @execution_helper.capture_status_from_command(cmd)
    end

    def capture_output_from_system(cmd, env = {})
      execution = @execution_helper.capture_status_and_output_from_command(cmd, env)

      raise(CommandFailed, '******** Build failed ********') unless execution[:success]

      execution[:output]
    end

    def check_command_for_failure(cmd)
      @out.puts "Executing #{cmd} and checking for FAILURE"
      execution = @execution_helper.capture_status_and_output_from_command("#{cmd} 2>&1")
      result = execution[:output]
      @out.puts "Results:"
      @out.puts result

      result.include?("Finished") && !result.include?("FAILURE") && !result.include?("EXCEPTION")
    end
  end
end
