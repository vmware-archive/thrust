module Thrust
  class IPABuilder
    def initialize(out, xcode_tools, agv_tool, git, app_config, deployment_config, deployment_target)
      @out = out
      @xcode_tools = xcode_tools
      @agv_tool = agv_tool
      @git = git
      @app_config = app_config
      @deployment_config = deployment_config
      @deployment_target = deployment_target
    end

    def run
      @git.ensure_clean

      begin
        @git.checkout_tag(@deployment_config.tag) if @deployment_config.tag

        if @deployment_config.versioning_method != 'none'
          if @deployment_config.versioning_method == 'commits'
            @agv_tool.change_build_number(@git.commit_count, nil, @app_config.path_to_xcodeproj)
          elsif @deployment_config.versioning_method == 'timestamp-sha'
            @agv_tool.change_build_number(@git.current_commit, Time.now.utc.strftime('%y%m%d%H%M'), @app_config.path_to_xcodeproj)
          else
            @agv_tool.change_build_number(@git.current_commit, nil, @app_config.path_to_xcodeproj)
          end
        end

        app_name = @app_config.app_name
        target = @deployment_config.target || app_name
        scheme = @deployment_config.scheme
        distribution_certificate = @deployment_config.distribution_certificate || @app_config.distribution_certificate
        if scheme != nil
          ipa_file = @xcode_tools.cleanly_create_ipa_with_scheme(scheme, app_name, distribution_certificate, @deployment_config.provisioning_search_query)
        else
          ipa_file = @xcode_tools.cleanly_create_ipa_with_target(target, app_name, distribution_certificate, @deployment_config.provisioning_search_query)
        end

        @out.puts "\n\n"
        @out.puts "Successfully built .ipa:".green
        @out.puts ipa_file
      rescue Exception => e
        @out.puts "\n\n"
        @out.puts e.message.red
        @out.puts "\n\n"

        exit 1
      ensure
        @git.reset
        @git.checkout_previous_branch if @deployment_config.tag
      end
    end
  end
end
