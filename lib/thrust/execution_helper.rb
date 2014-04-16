module Thrust
  class ExecutionHelper
    def capture_status_from_command(command, env = {})
      with_env_vars(env) do
        system(command)
      end
    end

    def capture_status_and_output_from_command(command, env = {})
      with_env_vars(env) do
        output = `#{command}`
        { success: $?.exitstatus == 0, output: output }
      end
    end

    private

    def with_env_vars(env, &block)
      saved_vars = {}
      env.each do |key, value|
        saved_vars[key] = ENV[key]
        ENV[key] = value
      end

      retval = yield block

      # reset some stuff
      saved_vars.each do |key, value|
        ENV[key] = value
      end

      retval
    end
  end
end
