module Thrust
  module Tasks
    class IOSSpecs
      def initialize(out = $stdout,
          xcode_tools_provider = Thrust::IOS::XCodeToolsProvider.new,
          cedar = Thrust::IOS::Cedar.new)
        @xcode_tools_provider = xcode_tools_provider
        @cedar = cedar
        @out = out
      end

      def run(thrust, target_info, args)
        build_configuration = target_info.build_configuration
        type = target_info.type
        target = target_info.target
        scheme = target_info.scheme
        build_sdk = target_info.build_sdk
        os_version = args[:os_version] || target_info.os_version
        device_name = args[:device_name] || target_info.device_name

        if device_name
          substitution_map = {'bundle' => '-', 'app' => ' '}
          destination_map = {'bundle' => ' ', 'app' => '-'}
          device_name.gsub!(substitution_map[type], destination_map[type])
        end

        tools_options = {
            project_name: thrust.app_config.project_name,
            workspace_name: thrust.app_config.workspace_name
        }
        xcode_tools = @xcode_tools_provider.instance(@out, build_configuration, thrust.build_dir, tools_options)

        if type == 'app'
          xcode_tools.build_scheme_or_target(scheme || target, build_sdk)
          xcode_tools.kill_simulator
          @cedar.run(build_configuration, target, build_sdk, os_version, device_name, target_info.timeout, thrust.build_dir, thrust.app_config.ios_sim_path)
        else
          xcode_tools.test(target || scheme, build_configuration, os_version, device_name, target_info.timeout, thrust.build_dir)
        end
      end
    end
  end
end
