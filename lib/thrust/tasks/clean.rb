module Thrust
  module Tasks
    class Clean
      def initialize(out = $stdout, xcode_tools_provider = Thrust::IOS::XCodeToolsProvider.new)
        @xcode_tools_provider = xcode_tools_provider
        @out = out
      end

      def run(thrust)
        tools_options = {
          project_name: thrust.app_config.project_name,
          workspace_name: thrust.app_config.workspace_name
        }

        xcode_tools = @xcode_tools_provider.instance(@out, nil, thrust.build_dir, tools_options)
        xcode_tools.clean_build
      end
    end
  end
end
