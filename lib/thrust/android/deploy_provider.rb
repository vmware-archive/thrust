module Thrust
  module Android
    class DeployProvider
      def instance(thrust_config, deployment_config, deployment_target)
        thrust_executor = Thrust::Executor.new
        tools = Thrust::Android::Tools.new($stdout, thrust_executor)
        git = Thrust::Git.new($stdout, thrust_executor)

        testflight_config = thrust_config.app_config.testflight
        testflight = Thrust::Testflight.new(thrust_executor, $stdout, $stdin, testflight_config.api_token, testflight_config.team_token)

        autogenerate_notes = deployment_config.note_generation_method == 'autotag'
        Thrust::Android::Deploy.new($stdout, tools, git, testflight, deployment_config.notify, deployment_config.distribution_list, autogenerate_notes, deployment_target)
      end
    end
  end
end
