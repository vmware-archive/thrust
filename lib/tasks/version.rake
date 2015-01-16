require_relative '../thrust'

@app_config = Thrust::ConfigLoader.load_configuration(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

desc 'Set build number'
task :set_build_number, :build_number do |_, args|
  if File.exists?('AndroidManifest.xml')
    Thrust::Android::Tools.new.change_build_number(Time.now.utc.strftime('%y%m%d%H%M'), args[:build_number])
  else
    path_to_xcodeproj = @app_config.path_to_xcodeproj
    Thrust::IOS::AgvTool.new.change_build_number(args[:build_number], nil, path_to_xcodeproj)
  end
end
