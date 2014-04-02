class Thrust::IOS::Deploy
  def initialize(out, x_code_tools, agv_tool, git, testflight, thrust_config, deployment_config, deployment_target)
    @out = out
    @x_code_tools = x_code_tools
    @agv_tool = agv_tool
    @git = git
    @testflight = testflight
    @thrust_config = thrust_config
    @deployment_config = deployment_config
    @deployment_target = deployment_target
  end

  def run
    @git.ensure_clean

    if (@deployment_config.versioning_method == 'commits')
      @agv_tool.change_build_number(@git.commit_count)
    else
      @agv_tool.change_build_number(@git.current_commit)
    end

    app_name = @thrust_config.app_config.app_name
    target = @deployment_config.ios_target || app_name

    ipa_file = @x_code_tools.cleanly_create_ipa(target, app_name, @thrust_config.app_config.ios_distribution_certificate, @deployment_config.ios_provisioning_search_query)

    dsym_path = "#{@x_code_tools.build_configuration_directory}/#{app_name}.app.dSYM"

    autogenerate_notes = @deployment_config.note_generation_method == 'autotag'
    @testflight.upload(ipa_file, @deployment_config.notify, @deployment_config.distribution_list, autogenerate_notes, @deployment_target, dsym_path)
    @git.reset
  end
end
