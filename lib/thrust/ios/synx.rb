module Thrust
  module IOS
    class Synx
      def initialize(project_name, thrust_executor = Thrust::Executor.new)
        @project_name = project_name
        @thrust_executor = thrust_executor
        raise "project_name required" unless !@project_name.nil?
      end

      def run
        @thrust_executor.system_or_exit "synx #{@project_name}.xcodeproj"
      end
    end
  end
end
