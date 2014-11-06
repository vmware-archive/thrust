require_relative '../thrust'

@thrust = Thrust::Config.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

desc 'Trim whitespace'
task :trim do
  Thrust::Tasks::Trim.new.run
end

desc 'Remove any focus from specs'
task :nof do
  Thrust::Tasks::Nof.new.run
end

desc 'Print out names of files containing focused specs'
task :focused_specs do
  Thrust::Tasks::FocusedSpecs.new.run(@thrust)
end

desc 'Clean all targets'
task :clean do
  Thrust::Tasks::Clean.new.run(@thrust)
end

desc 'Clean all targets (deprecated, use "clean")'
task :clean_build => :clean

@thrust.app_config.ios_spec_targets.each do |target_name, target_info|
  desc target_info.scheme ? "Run the #{target_info.scheme} scheme" : "Run the #{target_info.target} target"
  task target_name, :os_version, :device_name do |_, args|
    exit(1) unless Thrust::Tasks::IOSSpecs.new.run(@thrust, target_info, args)
  end
end
