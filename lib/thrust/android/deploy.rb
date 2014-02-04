class Thrust::Android::Deploy
  def self.make(thrust_config, deployment_config, deployment_target)
    thrust_executor = Thrust::Executor.new
    tools = Thrust::Android::Tools.new($stdout)
    git = Thrust::Git.new(thrust_executor, $stdout)

    testflight_config = thrust_config.app_config['testflight']
    testflight = Thrust::Testflight.new(thrust_executor, $stdout, $stdin, testflight_config['api_token'], testflight_config['team_token'])

    autogenerate_notes = deployment_config['note_generation_method'] == 'autotag'
    new($stdout, tools, git, testflight, deployment_config['notify'], deployment_config['distribution_list'], autogenerate_notes, deployment_target)
  end

  def initialize(out, tools, git, testflight, notify, distribution_list, autogenerate_notes, deployment_target)
    @out = out
    @tools = tools
    @git = git
    @testflight = testflight
    @notify = notify
    @distribution_list = distribution_list
    @deployment_target = deployment_target
    @autogenerate_notes = autogenerate_notes
  end

  def run
    @git.ensure_clean
    @tools.change_build_number(Time.now.utc.strftime('%y%m%d%H%M'), @git.current_commit)
    apk_path = @tools.build_signed_release

    @testflight.upload(apk_path, @notify, @distribution_list, @autogenerate_notes, @deployment_target)

    @git.reset
  end
end
