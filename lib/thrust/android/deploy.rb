module Thrust
  module Android
    class Deploy
      def initialize(out, tools, git, testflight, deployment_config, deployment_target)
        @out = out
        @tools = tools
        @git = git
        @testflight = testflight
        @deployment_config = deployment_config
        @deployment_target = deployment_target
      end

      def run
        @git.ensure_clean
        @git.checkout_tag(@deployment_config.tag) if @deployment_config.tag

        @tools.change_build_number(Time.now.utc.strftime('%y%m%d%H%M'), @git.current_commit)
        apk_path = @tools.build_signed_release

        autogenerate_notes = @deployment_config.note_generation_method == 'autotag'
        @testflight.upload(apk_path, @deployment_config.notify, @deployment_config.distribution_list, autogenerate_notes, @deployment_target)

        @git.create_tag(@deployment_target)
        @git.reset
      end
    end
  end
end
