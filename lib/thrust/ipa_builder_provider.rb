module Thrust
  class IPABuilderProvider
    def instance(app_config, deployment_config, deployment_target)
      stdout = $stdout
      thrust_executor = Thrust::Executor.new
      build_configuration = deployment_config.build_configuration
      tools_options = {project_name: app_config.project_name, workspace_name: app_config.workspace_name}
      xcode_tools = Thrust::XcodeToolsProvider.new.instance(stdout, build_configuration, app_config.build_directory, tools_options)
      git = Thrust::Git.new(stdout, thrust_executor)
      agv_tool = Thrust::AgvTool.new(thrust_executor, git)

      Thrust::IPABuilder.new(stdout, xcode_tools, agv_tool, git, app_config, deployment_config, deployment_target)
    end
  end
end
