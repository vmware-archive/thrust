module Thrust
  module Tasks
    module Autotag
      class List
        def initialize(git = Thrust::Git.new)
          @git = git
        end

        def run(app_config)
          app_config.deployment_targets.each do |deployment_target, _|
            puts @git.commit_summary_for_last_deploy(deployment_target)
          end
        end
      end
    end
  end
end
