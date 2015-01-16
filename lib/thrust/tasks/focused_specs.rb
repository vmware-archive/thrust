module Thrust
  module Tasks
    class FocusedSpecs
      FOCUSED_METHODS = %w[fit(@ fcontext(@ fdescribe(@]

      def initialize(executor = Thrust::Executor.new)
        @executor = executor
      end

      def run(app_config)
        pattern = FOCUSED_METHODS.join("\\|")
        directories = app_config.spec_directories.map{ |sd| "\"#{sd}\"" }.join(' ')
        @executor.system %Q[grep -l -r -e "\\(#{pattern}\\)" #{directories} | grep -v 'Frameworks']
      end
    end
  end
end
