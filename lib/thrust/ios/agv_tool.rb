module Thrust
  module IOS
    class AgvTool
      def initialize(thrust_executor = Thrust::Executor.new, git = Thrust::Git.new)
        @thrust_executor = thrust_executor
        @git = git
      end

      def change_build_number(build_number, path_to_xcodeproj)
        path_to_xcodeproj = path_to_xcodeproj ? File.dirname(path_to_xcodeproj) : '.'
        @thrust_executor.system_or_exit "cd #{path_to_xcodeproj} && agvtool new-version -all '#{build_number}'"
        @git.checkout_file("#{path_to_xcodeproj}/*.xcodeproj")
      end
    end
  end
end
