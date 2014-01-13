class Thrust::IOS::Deploy
  def self.make(thrust_config, deployment_config, provisioning_search_query)
    build_configuration = deployment_config['ios_build_configuration']
    x_code_tools = Thrust::IOS::XCodeTools.new($stdout, build_configuration, thrust_config.build_dir, thrust_config.app_config['project_name'])
    git = Thrust::Git.new($stdout)
    testflight_config = thrust_config.app_config['testflight']
    testflight = Thrust::Testflight.new($stdout, $stdin, testflight_config['api_token'], testflight_config['team_token'])

    new($stdout, x_code_tools, git, testflight, provisioning_search_query, thrust_config, deployment_config)
  end

  def initialize(out, x_code_tools, git, testflight, provisioning_search_query, thrust_config, deployment_config)
    @out = out
    @x_code_tools = x_code_tools
    @git = git
    @testflight = testflight
    @provisioning_search_query = provisioning_search_query
    @thrust_config = thrust_config
    @deployment_config = deployment_config
  end

  def run
    @git.ensure_clean
    @x_code_tools.change_build_number(@git.current_commit)

    app_name = @thrust_config.app_config['app_name']
    target = @deployment_config['ios_target'] || app_name
    ipa_file = @x_code_tools.cleanly_create_ipa(target, app_name, @thrust_config.app_config['ios_distribution_certificate'], @provisioning_search_query)

    dsym_path = "#{@x_code_tools.build_configuration_directory}/#{app_name}.app.dSYM"
    @testflight.upload(ipa_file, @deployment_config['notify'], @deployment_config['distribution_list'], dsym_path)
    @git.reset
  end
end
