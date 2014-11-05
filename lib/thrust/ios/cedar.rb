require 'tmpdir'

module Thrust
  module IOS
    class Cedar
      def initialize(out = $stdout, thrust_executor = Thrust::Executor.new)
        @thrust_executor = thrust_executor
        @out = out
      end

      def run(build_configuration, target, build_sdk, os_version, device_name, build_dir, simulator_binary)
        if build_sdk == 'macosx'
          build_path = File.join(build_dir, build_configuration)
          app_dir = File.join(build_path, target)
          @thrust_executor.check_command_for_failure(app_dir.inspect, {'DYLD_FRAMEWORK_PATH' => build_path.inspect})
        else
          device_type_id = "com.apple.CoreSimulator.SimDeviceType.#{device_name}, #{os_version}"

          app_executable = File.join(build_dir, "#{build_configuration}-#{build_sdk}", "#{target}.app")
          simulator_binary ||= 'ios-sim'
          @thrust_executor.check_command_for_failure(%Q[#{simulator_binary} launch #{app_executable} --devicetypeid '#{device_type_id}' --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
        end
      end
    end
  end
end
