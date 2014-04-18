module Thrust
  class ExecutionHelper
    def capture_status_from_command(command, env = {})
      system(env, command)
    end

    def capture_status_and_output_from_command(command, env = {})
      env_string = ''
      for key in env.keys
        env_string += "#{key}=#{env[key]} "
      end

      output = `#{env_string}#{command}`
      { success: $?.exitstatus == 0, output: output }
    end
  end
end
