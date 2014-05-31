require_relative '../thrust'

@thrust = Thrust::Config.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

if !File.exists?('AndroidManifest.xml')
  desc 'Sync directory structure with Xcode groups'
  task :synx do
    Thrust::IOS::Synx.new(@thrust.app_config.project_name).run
  end
end
