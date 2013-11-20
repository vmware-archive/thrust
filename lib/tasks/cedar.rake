require 'yaml'
require 'tmpdir'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'thrust_config'))

@thrust = ThrustConfig.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

desc 'Trim whitespace'
task :trim do
  awk_statement = <<-AWK
  {
    if ($1 == "RM" || $1 == "R")
      print $4;
    else if ($1 != "D")
      print $2;
  }
  AWK
  awk_statement.gsub!(%r{\s+}, " ")

  @thrust.system_or_exit %Q[git status --short | awk '#{awk_statement}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
end

desc "Remove any focus from specs"
task :nof do
  substitutions = focused_methods.map do |method|
    unfocused_method = method.sub(/^f/, '')
    "-e 's/#{method}/#{unfocused_method}/g;'"
  end

  @thrust.system_or_exit %Q[ rake focused_specs | xargs -I filename sed -i '' #{substitutions.join(' ')} "filename" ]
end

desc "Print out names of files containing focused specs"
task :focused_specs do
  pattern = focused_methods.join("\\|")
  directories = @thrust.config['spec_targets'].values.map {|h| h['target']}.join(' ')
  @thrust.system_or_exit %Q[ grep -l -r -e "\\(#{pattern}\\)" #{directories} | grep -v 'Frameworks' ; exit 0 ]
end

desc 'Clean all targets'
task :clean do
  @thrust.xcode_build_configurations.each do |config|
    @thrust.xcode_clean(config)
  end
end

@thrust.config['spec_targets'].each do |task_name, info|
  desc "Run #{info['name']}"
  task task_name do
    build_configuration = info['configuration']
    target = info['target']
    sdk = info['sdk']
    os = info['os'] || 'iphonesimulator'

    @thrust.xcode_clean(build_configuration)
    @thrust.xcode_build(build_configuration, os, target)
    @thrust.run_cedar(build_configuration, target, sdk, os, info['device'])
  end
end

def focused_methods
  ["fit", "fcontext", "fdescribe"].map { |method| "#{method}(@" }
end
