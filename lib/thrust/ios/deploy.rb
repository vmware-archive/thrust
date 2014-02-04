class Thrust::IOS::Deploy
  def self.make(thrust_config, deployment_config, deployment_target)
    build_configuration = deployment_config['ios_build_configuration']
    tools_options = { project_name: thrust_config.app_config['project_name'], workspace_name: thrust_config.app_config['workspace_name'] }
    x_code_tools = Thrust::IOS::XCodeToolsProvider.new.instance($stdout, build_configuration, thrust_config.build_dir, tools_options)
    git = Thrust::Git.new($stdout)
    testflight_config = thrust_config.app_config['testflight']
    testflight = Thrust::Testflight.new($stdout, $stdin, testflight_config['api_token'], testflight_config['team_token'])

    new($stdout, x_code_tools, git, testflight, thrust_config, deployment_config, deployment_target)
  end

  def initialize(out, x_code_tools, git, testflight, thrust_config, deployment_config, deployment_target)
    @out = out
    @x_code_tools = x_code_tools
    @git = git
    @testflight = testflight
    @thrust_config = thrust_config
    @deployment_config = deployment_config
    @deployment_target = deployment_target
  end

  def run
    @git.ensure_clean
    @x_code_tools.change_build_number(@git.current_commit)

    app_name = @thrust_config.app_config['app_name']
    target = @deployment_config['ios_target'] || app_name
    ipa_file = @x_code_tools.cleanly_create_ipa(target, app_name, @thrust_config.app_config['ios_distribution_certificate'], @deployment_config['ios_provisioning_search_query'])

    dsym_path = "#{@x_code_tools.build_configuration_directory}/#{app_name}.app.dSYM"

    autogenerate_notes = @deployment_config['note_generation_method'] == 'autotag'
    @testflight.upload(ipa_file, @deployment_config['notify'], @deployment_config['distribution_list'], autogenerate_notes, @deployment_target, dsym_path)
    @git.reset
  end
end
