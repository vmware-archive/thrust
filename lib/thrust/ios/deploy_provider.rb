module Thrust
  module IOS
    class DeployProvider
      def instance(app_config, deployment_config, deployment_target)
        stdout = $stdout
        thrust_executor = Thrust::Executor.new
        build_configuration = deployment_config.ios_build_configuration
        tools_options = {project_name: app_config.project_name, workspace_name: app_config.workspace_name}
        xcode_tools = Thrust::IOS::XcodeToolsProvider.new.instance(stdout, build_configuration, app_config.build_directory, tools_options)
        git = Thrust::Git.new(stdout, thrust_executor)
        agv_tool = Thrust::IOS::AgvTool.new(thrust_executor, git)
        testflight_config = app_config.testflight
        testflight = Thrust::Testflight.new(thrust_executor, stdout, $stdin, testflight_config.api_token, testflight_config.team_token)

        Thrust::IOS::Deploy.new(stdout, xcode_tools, agv_tool, git, testflight, app_config, deployment_config, deployment_target)
      end
    end
  end
end
