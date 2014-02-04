class Thrust::Android::DeployProvider
  def instance(thrust_config, deployment_config, deployment_target)
    thrust_executor = Thrust::Executor.new
    tools = Thrust::Android::Tools.new(thrust_executor, $stdout)
    git = Thrust::Git.new(thrust_executor, $stdout)

    testflight_config = thrust_config.app_config['testflight']
    testflight = Thrust::Testflight.new(thrust_executor, $stdout, $stdin, testflight_config['api_token'], testflight_config['team_token'])

    autogenerate_notes = deployment_config['note_generation_method'] == 'autotag'
    Thrust::Android::Deploy.new($stdout, tools, git, testflight, deployment_config['notify'], deployment_config['distribution_list'], autogenerate_notes, deployment_target)
  end
end
