module Thrust
  module Tasks
    module Autotag
      class Create
        def run(stage)
          `autotag create #{stage}`
        end
      end
    end
  end
end
