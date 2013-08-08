require 'yaml'
require 'tmpdir'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'thrust_config'))

@thrust = ThrustConfig.new(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

task :default => [:trim, :specs]

desc 'Trim whitespace'
task :trim do
  @thrust.system_or_exit %Q[git status --short | awk '{if ($1 != "D" && $1 != "R") print $2}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
end

desc "Remove any focus from specs"
task :nof do
  @thrust.system_or_exit %Q[ rake focused_specs | xargs -I{} sed -i '' -e 's/fit\(@/it\(@/g;' -e 's/fdescribe\(@/describe\(@/g;' -e 's/fcontext\(@/context\(@/g;' "{}" ]
end

desc "Print out names of files containing focused specs"
task :focused_specs do
  @thrust.system_or_exit %Q[ grep -l -r -e "\\(fit\\|fdescribe\\|fcontext\\)" #{ @thrust.config['spec_targets'].values.map {|h| h['target']}.join(' ') } | grep -v 'Frameworks' ; exit 0 ]
end

desc 'Clean all targets'
task :clean do
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration 'AdHoc' -sdk iphoneos clean", @thrust.output_file("clean")
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration 'Debug' -sdk iphonesimulator clean", @thrust.output_file("clean")
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration 'Release' -sdk iphonesimulator clean", @thrust.output_file("clean")
end

task :build_specs, :target, :build_configuration do |task_name, args|
  @thrust.kill_simulator
  # TODO: ARCHS=i386 ONLY_ACTIVE_ARCH=NO
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -target #{args[:target]} -configuration #{args[:build_configuration]} -sdk iphonesimulator build", @thrust.output_file("specs")
end

task :run_cedar, :target, :sdk, :build_configuration do |task_name, args|
  binary = @thrust.config['sim_binary']
  sim_dir = File.join(@thrust.build_dir, "#{args[:build_configuration]}-iphonesimulator", "#{args[:target]}.app")
  if binary =~ /waxim%/
    @thrust.grep_cmd_for_failure(%Q[#{binary} -s #{@args[:sdk]} -f iphone -e CFFIXED_USER_HOME=#{Dir.tmpdir} -e CEDAR_HEADLESS_SPECS=1 -e CEDAR_REPORTER_CLASS=CDRDefaultReporter #{sim_dir}])
  elsif binary =~ /ios-sim$/
    @thrust.grep_cmd_for_failure(%Q[#{binary} launch #{sim_dir} --sdk #{args[:sdk]} --family iphone --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
  else
    puts "Unknown binary for running specs: '#{binary}'"
    exit(1)
  end
end

@thrust.config['spec_targets'].each do |task_name, info|
  desc "Run #{info['name']}"
  task task_name => :clean do
    Rake::Task["build_specs"].invoke(info['target'], info['configuration'])
    Rake::Task["run_cedar"].invoke(info['target'], info['sdk'], info['configuration'])
  end
end
