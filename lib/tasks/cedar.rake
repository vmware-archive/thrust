require 'yaml'
require 'tmpdir'
require File.expand_path('../../thrust', __FILE__)

@thrust = Thrust::Config.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))
@xcode_tools_provider = Thrust::IOS::XCodeToolsProvider.new
@executor = Thrust::Executor.new

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

  @executor.system_or_exit %Q[git status --porcelain | awk '#{awk_statement}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
end

desc 'Remove any focus from specs'
task :nof do
  substitutions = focused_methods.map do |method|
    unfocused_method = method.sub(/^f/, '')
    "-e 's/#{method}/#{unfocused_method}/g;'"
  end

  @executor.system_or_exit %Q[ rake focused_specs | xargs -I filename sed -i '' #{substitutions.join(' ')} "filename" ]
end

desc 'Print out names of files containing focused specs'
task :focused_specs do
  pattern = focused_methods.join("\\|")
  directories = @thrust.app_config['ios_spec_targets'].values.map {|h| h['target']}.join(' ')
  @executor.system_or_exit %Q[ grep -l -r -e "\\(#{pattern}\\)" #{directories} | grep -v 'Frameworks' ; exit 0 ]
end

desc 'Clean all targets'
task :clean do
  xcode_tools_instance(nil).clean_build
end

desc 'Clean all targets (deprecated, use "clean")'
task :clean_build => :clean

(@thrust.app_config['ios_spec_targets'] || []).each do |task_name, target_info|
  desc "Run the #{target_info['target'].inspect} target with scheme #{(target_info['scheme'] || target_info['target']).inspect}"
  task task_name, :runtime_sdk do |_, args|
    build_configuration = target_info['build_configuration']
    target = target_info['target']
    scheme = target_info['scheme']
    build_sdk = target_info['build_sdk'] || 'iphonesimulator' #build sdk - version you compile the code with
    runtime_sdk = args[:runtime_sdk] || target_info['runtime_sdk'] #runtime sdk

    xcode_tools = xcode_tools_instance(build_configuration)
    xcode_tools.build_scheme_or_target(scheme || target, build_sdk, 'i386')

    cedar_success = Thrust::IOS::Cedar.new.run($stdout, build_configuration, target, runtime_sdk, build_sdk, target_info['device'], @thrust.build_dir, @thrust.app_config['ios_sim_binary'])

		exit(cedar_success ? 0 : 1)
  end
end

def focused_methods
  %w(fit fcontext fdescribe).map { |method| "#{method}(@" }
end

def xcode_tools_instance(build_configuration)
  tools_options = { project_name: @thrust.app_config['project_name'], workspace_name: @thrust.app_config['workspace_name'] }
  @xcode_tools_provider.instance($stdout, build_configuration, @thrust.build_dir, tools_options)
end
