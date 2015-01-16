module Thrust
  module Android
    class DeployProvider
      def instance(app_config, deployment_config, deployment_target)
        thrust_executor = Thrust::Executor.new
        tools = Thrust::Android::Tools.new($stdout, thrust_executor)
        git = Thrust::Git.new($stdout, thrust_executor)

        testflight_config = app_config.testflight
        testflight = Thrust::Testflight.new(thrust_executor, $stdout, $stdin, testflight_config.api_token, testflight_config.team_token)

        Thrust::Android::Deploy.new($stdout, tools, git, testflight, deployment_config, deployment_target)
      end
    end
  end
end
