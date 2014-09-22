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
        runtime_sdk = args[:runtime_sdk] || target_info.runtime_sdk

        tools_options = {
          project_name: thrust.app_config.project_name,
          workspace_name: thrust.app_config.workspace_name
        }

        xcode_tools = @xcode_tools_provider.instance(@out, build_configuration, thrust.build_dir, tools_options)
        xcode_tools.build_scheme_or_target(scheme || target, build_sdk)

        if type == 'app'
          xcode_tools.kill_simulator
          @cedar.run(build_configuration, target, runtime_sdk, build_sdk, target_info.device, target_info.device_type_id, thrust.build_dir, thrust.app_config.ios_sim_binary)
        else
          xcode_tools.test(target || scheme, build_configuration, runtime_sdk, thrust.build_dir)
        end
      end
    end
  end
end
