class Thrust::Android::Deploy
  def self.make(thrust_config, distribution_config)
    tools = Thrust::Android::Tools.new($stdout)
    git = Thrust::Git.new($stdout)
    testflight = Thrust::Testflight.new($stdout, $stdin, thrust_config.app_config['api_token'], distribution_config['token'])
    self.new($stdout, tools, git, testflight, distribution_config['notify'], distribution_config['default_list'])
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
