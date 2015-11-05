module Thrust
  module Tasks
    class FocusedSpecs
      FOCUSED_METHODS = %w[fit(@ fcontext(@ fdescribe(@ fit(\" fcontext(\" fdescribe(\"]

      def initialize(out = $stdout, executor = Thrust::Executor.new)
        @out = out
        @executor = executor
      end

      def run(app_config)
        if app_config.spec_directories.empty?
          @out.puts 'Unable to find focused specs without `spec_directories` defined in thrust.yml.'.red
          exit 1
        end

        pattern = FOCUSED_METHODS.join("\\|")
        directories = app_config.spec_directories.map{ |sd| "\"#{sd}\"" }.join(' ')
        output = @executor.capture_output_from_system %Q[grep -l -r -e "\\(#{pattern}\\)" #{directories} | grep -v 'Frameworks' || true]

        @out.puts output

        output.split("\n")
      end
    end
  end
end
