module Thrust
  module Android
    class Deploy
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
  end
end
