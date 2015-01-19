module Thrust
  module Tasks
    class Clean
      def initialize(out = $stdout, xcode_tools_provider = Thrust::XcodeToolsProvider.new)
        @xcode_tools_provider = xcode_tools_provider
        @out = out
      end

      def run(app_config)
        tools_options = {
          project_name: app_config.project_name,
          workspace_name: app_config.workspace_name
        }

        xcode_tools = @xcode_tools_provider.instance(@out, nil, app_config.build_directory, tools_options)
        xcode_tools.clean_build
      end
    end
  end
end
