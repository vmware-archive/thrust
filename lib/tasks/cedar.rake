require 'yaml'
require 'tmpdir'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'thrust_config'))

@thrust = ThrustConfig.new(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

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
  @thrust.xcodeclean('AdHoc', 'iphoneos')
  @thrust.xcodeclean('Debug', 'iphoneos')
  @thrust.xcodeclean('Release', 'iphoneos')
end

@thrust.config['spec_targets'].each do |task_name, info|
  desc "Run #{info['name']}"
  task task_name do
    build_configuration = info['configuration']
    target = info['target']
    sdk = info['sdk']

    @thrust.xcodeclean(build_configuration, 'iphonesimulator')
    @thrust.xcodebuild(build_configuration, 'iphonesimulator', target)
    @thrust.run_cedar(build_configuration, target, sdk, info['device'])
  end
end
