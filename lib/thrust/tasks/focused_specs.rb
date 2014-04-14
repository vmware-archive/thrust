module Thrust
  module Tasks
    class FocusedSpecs
      FOCUSED_METHODS = %w[fit(@ fcontext(@ fdescribe(@]

      def initialize(executor = Thrust::Executor.new)
        @executor = executor
      end

      def run(thrust)
        pattern = FOCUSED_METHODS.join("\\|")
        directories = thrust.app_config.ios_spec_targets.values.map(&:target).join(' ')
        @executor.system_or_exit %Q[grep -l -r -e "\\(#{pattern}\\)" #{directories} | grep -v 'Frameworks'; exit 0]
      end
    end
  end
end
