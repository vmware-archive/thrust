class Thrust::Android::Deploy
  def self.make(thrust_config, deployment_config)
    tools = Thrust::Android::Tools.new($stdout)
    git = Thrust::Git.new($stdout)

    testflight_config = thrust_config.app_config['testflight']
    testflight = Thrust::Testflight.new($stdout, $stdin, testflight_config['api_token'], testflight_config['team_token'])

    self.new($stdout, tools, git, testflight, deployment_config['notify'], deployment_config['distribution_list'])
  end

  def initialize(out, tools, git, testflight, notify, distribution_list)
    @out = out
    @tools = tools
    @git = git
    @testflight = testflight
    @notify = notify
    @distribution_list = distribution_list
  end

  def run
    @git.ensure_clean
    @tools.change_build_number(Time.now.strftime('%y%m%d%H%M'), @git.current_commit)
    apk_path = @tools.build_signed_release
    @testflight.upload(apk_path, @notify, @distribution_list)
    @git.reset
  end
end
