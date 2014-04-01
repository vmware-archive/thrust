module Thrust
  module Tasks
    module Autotag
      class List
        def run(thrust)
          thrust.app_config['deployment_targets'].each do |deployment_target, _|
            puts Thrust::Git.new.commit_summary_for_last_deploy(deployment_target)
          end
        end
      end
    end
  end
end
