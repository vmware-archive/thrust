module Thrust
  module Tasks
    class Nof
      FOCUSED_METHODS = %w[fit(@ fcontext(@ fdescribe(@]

      def initialize(executor = Thrust::Executor.new)
        @executor = executor
      end

      def run
        substitutions = FOCUSED_METHODS.map do |method|
          unfocused_method = method.sub(/^f/, '')
          "-e 's/#{method}/#{unfocused_method}/g;'"
        end

        @executor.system_or_exit %Q[rake focused_specs | xargs -I filename sed -i '' #{substitutions.join(' ')} "filename"]
      end
    end
  end
end
