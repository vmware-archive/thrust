require File.expand_path('../../thrust', __FILE__)

desc 'Set build number'
task :set_build_number, :build_number do |_, args|
  executor = Thrust::Executor.new

  if File.exists?('AndroidManifest.xml')
    Thrust::Android::Tools.new(executor, $stdout).change_build_number(Time.now.utc.strftime('%y%m%d%H%M'), args[:build_number])
  else
    Thrust::IOS::AgvTool.new(executor, $stdout).change_build_number(args[:build_number])
  end
end
