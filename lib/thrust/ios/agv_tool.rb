module Thrust
  module IOS
    class AgvTool
      def initialize(thrust_executor = Thrust::Executor.new, git = Thrust::Git.new)
        @thrust_executor = thrust_executor
        @git = git
      end

      def change_build_number(build_number)
        @thrust_executor.system_or_exit "agvtool new-version -all '#{build_number}'"
        @git.checkout_file('*.xcodeproj')
      end
    end
  end
end
