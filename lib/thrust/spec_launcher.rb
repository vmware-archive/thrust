require 'tmpdir'

module Thrust
  class SpecLauncher
    def initialize(out = $stdout, thrust_executor = Thrust::Executor.new)
      @thrust_executor = thrust_executor
      @out = out
    end

    def run(executable_name, build_configuration, build_sdk, os_version, device_name, timeout, build_dir, simulator_binary, environment_variables)
      if build_sdk.include?('macosx')
        build_path = File.join(build_dir, build_configuration)
        app_executable = File.join(build_path, executable_name)
        @thrust_executor.check_command_for_failure("\"#{app_executable}\"", {'DYLD_FRAMEWORK_PATH' => "\"#{build_path}\""})
      else
        device_type_id = "com.apple.CoreSimulator.SimDeviceType.#{device_name}, #{os_version}"
        app_executable = File.join(build_dir, "#{build_configuration}-#{build_sdk}", "#{executable_name}.app")
        simulator_binary ||= 'ios-sim'

        arguments = ["--devicetypeid \"#{device_type_id}\"",
                     "--timeout #{timeout || '30'}",
                     "--setenv CFFIXED_USER_HOME=\"#{Dir.tmpdir}\"",
                     "--setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter"]
        environment_variables.each do |key, value|
          arguments << "--setenv #{key}=\"#{value}\""
        end

        @thrust_executor.check_command_for_failure("#{simulator_binary} launch #{app_executable} #{arguments.compact.join(' ')}")
      end
    end
  end
end
