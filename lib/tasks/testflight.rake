require 'yaml'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'xcode_config'))

@thrust_config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'thrust.yml'))

namespace :bump do
  desc 'Bumps the build'
  task :build do
    run_git_with_message 'Bumped build to $(agvtool what-version -terse)' do
      XcodeConfig.system_or_exit 'agvtool bump -all'
    end
  end

  namespace :version do
    desc 'Bumps the major marketing version in (major.minor.patch)'
    task :major do
      XcodeConfig.update_version(:major)
    end

    desc 'Bumps the minor marketing version in (major.minor.patch)'
    task :minor do
      XcodeConfig.update_version(:minor)
    end

    desc 'Bumps the patch marketing version in (major.minor.patch)'
    task :patch do
      XcodeConfig.update_version(:patch)
    end
  end
end

desc 'Build custom configuration'
task :build_configuration, :configuration do |task_name, args|
  build_prefix = XcodeConfig.build_prefix_for(args[:configuration])
  XcodeConfig.system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration '#{args[:configuration]}' -sdk iphoneos clean", XcodeConfig.output_file("clean")
  XcodeConfig.kill_simulator
  XcodeConfig.system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -target #{@thrust_config['app_name']} -configuration '#{args[:configuration]}' -sdk iphoneos build", XcodeConfig.output_file(args[:configuration])
  XcodeConfig.system_or_exit "/usr/bin/xcrun -sdk iphoneos PackageApplication -v '#{build_prefix}.app' -o '#{build_prefix}.ipa' --sign '#{@thrust_config['identity']}'"
  XcodeConfig.system_or_exit "zip -r -T -y '#{build_prefix}.app.dSYM.zip' '#{build_prefix}.app.dSYM'"
end

namespace :testflight do
  @thrust_config['distributions'].each do |task_name, info|
    desc "Deploy build to testflight #{info['team']} team (use NOTIFY=false to prevent team notification)"
    task task_name do
      Rake::Task["testflight:deploy"].invoke(info['token'], info['default_list'], info['configuration'])
    end
  end

  task :deploy, :team, :distribution_list, :configuration do |task, args|
    build_prefix = XcodeConfig.build_prefix_for(args[:configuration])
    Rake::Task["bump:build"].invoke
    Rake::Task["build_configuration"].invoke(args[:configuration])
    XcodeConfig.system_or_exit "curl http://testflightapp.com/api/builds.json\
      -F file=@#{build_prefix}.ipa\
      -F dsym=@#{build_prefix}.app.dSYM.zip\
      -F api_token='#{@thrust_config['api_token']}'\
      -F team_token='#{args[:team]}'\
      -F notes='This build was uploaded via the upload API'\
      -F notify=#{(ENV['NOTIFY'] || 'true').downcase.capitalize}\
      #{"-F distribution_lists='#{args[:distribution_list]}'" if args[:distribution_list]}"
  end
end
