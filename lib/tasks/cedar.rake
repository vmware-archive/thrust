require 'yaml'
require 'tmpdir'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'thrust_config'))

@thrust = ThrustConfig.new(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

task :default => [:trim, :specs]

desc 'Trim whitespace'
task :trim do
  @thrust.system_or_exit %Q[git status --short | awk '{if ($1 != "D" && $1 != "R") print $2}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
end

desc 'Clean all targets'
task :clean do
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration 'AdHoc' -sdk iphoneos clean", @thrust.output_file("clean")
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration 'Debug' -sdk iphonesimulator clean", @thrust.output_file("clean")
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration 'Release' -sdk iphonesimulator clean", @thrust.output_file("clean")
end

desc 'Build specs'
task :build_specs do
  @thrust.kill_simulator
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -target #{@thrust.spec_config['target']} -configuration #{@thrust.spec_config['configuration']} -sdk iphonesimulator build", @thrust.output_file("specs")
end

desc 'Run specs'
task :specs => :build_specs do
  binary = @thrust.spec_config['binary']
  if binary =~ /waxim%/
    @thrust.grep_cmd_for_failure(%Q[#{binary} -s #{@thrust.spec_config['sdk']} -f iphone -e CFFIXED_USER_HOME=#{Dir.tmpdir} -e CEDAR_HEADLESS_SPECS=1 -e CEDAR_REPORTER_CLASS=CDRDefaultReporter #{File.join(sim_dir, "#{@thrust.spec_config['target']}.app")}])
  elsif binary =~ /ios-sim$/
    @thrust.grep_cmd_for_failure(%Q[#{binary} launch #{File.join(@thrust.sim_dir, "#{@thrust.spec_config['target']}.app")} --sdk #{@thrust.spec_config['sdk']} --family iphone --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
  else
    puts "Uknown binary for running specs: '#{binary}'"
    exit(1)
  end
end
