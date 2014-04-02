class Thrust::IOS::AgvTool

  def initialize(thrust_executor, out)
    @thrust_executor = thrust_executor
    @out = out
    @git = Thrust::Git.new(@out, @thrust_executor)
  end

  def change_build_number(build_number)
    @thrust_executor.system_or_exit "agvtool new-version -all '#{build_number}'"
    @git.checkout_file('*.xcodeproj')
  end
end
