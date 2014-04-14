module Thrust
  class ExecutionHelper
    def capture_status_from_command(command)
      system(command)
    end

    def capture_status_and_output_from_command(command)
      output = `#{command}`
      [$?.exitstatus == 0, output]
    end
  end
end
