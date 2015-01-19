module Thrust
  module IOS
    class XcodeToolsProvider
      def initialize(thrust_executor = Thrust::Executor.new)
        @thrust_executor = thrust_executor
      end

      def instance(out, build_configuration, build_directory, options)
        Thrust::IOS::XcodeTools.new(@thrust_executor, out, build_configuration, build_directory, options)
      end
    end
  end
end
