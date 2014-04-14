module Thrust
  module Tasks
    module Autotag
      class Create
        def initialize(executor = Thrust::Executor.new)
          @executor = executor
        end

        def run(stage)
          @executor.capture_output_from_system("autotag create #{stage}")
        end
      end
    end
  end
end
