module Thrust
  module Tasks
    class Nof
      FOCUSED_METHODS = %w[fit(@ fcontext(@ fdescribe(@ fit(\" fcontext(\" fdescribe(\"]

      def initialize(executor = Thrust::Executor.new, focused_specs = Thrust::Tasks::FocusedSpecs.new)
        @executor = executor
        @focused_specs = focused_specs
      end

      def run(app_config)
        substitutions = FOCUSED_METHODS.map do |method|
          unfocused_method = method.sub(/^f/, '')
          "-e 's/#{method}/#{unfocused_method}/g;'"
        end

        focused_spec_files = @focused_specs.run(app_config)
        unless focused_spec_files.empty?
          quoted_spec_files = focused_spec_files.map { |file| "\"#{file}\"" }.join(' ')
          @executor.system_or_exit %Q[sed -i '' #{substitutions.join(' ')} #{quoted_spec_files}]
        end
      end
    end
  end
end
