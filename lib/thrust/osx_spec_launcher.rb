module Thrust
  class OSXSpecLauncher
    def initialize(out = $stdout, thrust_executor = Thrust::Executor.new)
      @thrust_executor = thrust_executor
      @out = out
    end

    def run(executable_name, build_configuration, build_directory)
      build_path = File.join(build_directory, build_configuration)
      app_executable = File.join(build_path, executable_name)
      @thrust_executor.check_command_for_failure("\"#{app_executable}\"", {'DYLD_FRAMEWORK_PATH' => "\"#{build_path}\""})
    end
  end
end
