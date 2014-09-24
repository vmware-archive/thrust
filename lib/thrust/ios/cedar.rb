require 'tmpdir'

module Thrust
  module IOS
    class Cedar
      def initialize(out = $stdout, thrust_executor = Thrust::Executor.new)
        @thrust_executor = thrust_executor
        @out = out
      end

      def run(build_configuration, target, runtime_sdk, build_sdk, device, device_type_id, build_dir, simulator_binary)
        if build_sdk == 'macosx'
          build_path = File.join(build_dir, build_configuration)
          app_dir = File.join(build_path, target)
          @thrust_executor.check_command_for_failure(app_dir.inspect, {'DYLD_FRAMEWORK_PATH' => build_path.inspect})
        else
          app_executable = File.join(build_dir, "#{build_configuration}-#{build_sdk}", "#{target}.app")

          if simulator_binary =~ /waxim%/
            @thrust_executor.check_command_for_failure(%Q[#{simulator_binary} -s #{runtime_sdk} -f #{device} -e CFFIXED_USER_HOME=#{Dir.tmpdir} -e CEDAR_HEADLESS_SPECS=1 -e CEDAR_REPORTER_CLASS=CDRDefaultReporter #{app_executable}])
          elsif simulator_binary =~ /ios-sim$/
            if (device_type_id.nil?)
              if device == "ipad"
                @thrust_executor.check_command_for_failure(%Q[#{simulator_binary} launch #{app_executable} --sdk #{runtime_sdk} --family #{device} --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
              else
                @thrust_executor.check_command_for_failure(%Q[#{simulator_binary} launch #{app_executable} --sdk #{runtime_sdk} --family #{device} --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
              end
            else
              @thrust_executor.check_command_for_failure(%Q[#{simulator_binary} launch #{app_executable} --devicetypeid '#{device_type_id}' --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
            end

          else
            @out.puts "Unknown binary for running specs: '#{simulator_binary}'"
            false
          end
        end
      end
    end
  end
end
