module Thrust
  module IOS
    class Deploy
      def initialize(out, xcode_tools, agv_tool, git, testflight, app_config, deployment_config, deployment_target)
        @out = out
        @xcode_tools = xcode_tools
        @agv_tool = agv_tool
        @git = git
        @testflight = testflight
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
          target = @deployment_config.ios_target || app_name

          ipa_file = @xcode_tools.cleanly_create_ipa(target, app_name, @app_config.ios_distribution_certificate, @deployment_config.ios_provisioning_search_query)

          dsym_path = "#{@xcode_tools.build_configuration_directory}/#{app_name}.app.dSYM"
          dsym_path = nil unless File.exist?(dsym_path)

          autogenerate_notes = @deployment_config.note_generation_method == 'autotag'
          @testflight.upload(ipa_file, @deployment_config.notify, @deployment_config.distribution_list, autogenerate_notes, @deployment_target, dsym_path)

          @git.create_tag(@deployment_target)
          @git.reset
        rescue Exception => e
          @out.puts "\n\n"
          @out.puts e.message.red
          @out.puts "\n\n"

          @git.reset
          exit 1
        end
      end
    end
  end
end
