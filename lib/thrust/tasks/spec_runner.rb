module Thrust
  module Tasks
    class SpecRunner
      def initialize(out = $stdout,
          xcode_tools_provider = Thrust::XcodeToolsProvider.new,
          cedar = Thrust::Cedar.new)
        @xcode_tools_provider = xcode_tools_provider
        @cedar = cedar
        @out = out
      end

      def run(app_config, target_info, args)
        build_configuration = target_info.build_configuration
        type = target_info.type
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
            project_name: app_config.project_name,
            workspace_name: app_config.workspace_name
        }
        xcode_tools = @xcode_tools_provider.instance(@out, build_configuration, app_config.build_directory, tools_options)

        if type == 'app'
          xcode_tools.build_scheme(scheme, build_sdk)
          xcode_tools.kill_simulator
          executable = xcode_tools.find_executable_name(scheme)
          @cedar.run(executable, build_configuration, build_sdk, os_version, device_name, target_info.timeout, app_config.build_directory, app_config.ios_sim_path)
        else
          xcode_tools.test(scheme, build_configuration, os_version, device_name, target_info.timeout, app_config.build_directory)
        end
      end
    end
  end
end
