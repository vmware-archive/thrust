module Thrust
  module IOS
    class DeployProvider
      def instance(thrust_config, deployment_config, deployment_target)
        stdout = $stdout
        thrust_executor = Thrust::Executor.new
        build_configuration = deployment_config.ios_build_configuration
        tools_options = {project_name: thrust_config.app_config.project_name, workspace_name: thrust_config.app_config.workspace_name}
        x_code_tools = Thrust::IOS::XCodeToolsProvider.new.instance(stdout, build_configuration, thrust_config.build_dir, tools_options)
        git = Thrust::Git.new(stdout, thrust_executor)
        agv_tool = Thrust::IOS::AgvTool.new(thrust_executor, git)
        testflight_config = thrust_config.app_config.testflight
        testflight = Thrust::Testflight.new(thrust_executor, stdout, $stdin, testflight_config.api_token, testflight_config.team_token)

        Thrust::IOS::Deploy.new(stdout, x_code_tools, agv_tool, git, testflight, thrust_config, deployment_config, deployment_target)
      end
    end
  end
end
