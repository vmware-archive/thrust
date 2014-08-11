require_relative '../thrust'

@thrust = Thrust::Config.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

desc 'Set build number'
task :set_build_number, :build_number do |_, args|
  if File.exists?('AndroidManifest.xml')
    Thrust::Android::Tools.new.change_build_number(Time.now.utc.strftime('%y%m%d%H%M'), args[:build_number])
  else
    path_to_xcodeproj = @thrust.app_config.path_to_xcodeproj
    Thrust::IOS::AgvTool.new.change_build_number(args[:build_number], path_to_xcodeproj)
  end
end
