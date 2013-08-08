require 'yaml'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'thrust_config'))
require 'tempfile'

@thrust = ThrustConfig.new(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

desc "show the current build"
task :current_version do
  @thrust.system_or_exit("agvtool what-version -terse")
end

namespace :bump do
  desc 'Bumps the build'
  task :build do
    @thrust.run_git_with_message 'Bumped build to $(agvtool what-version -terse)' do
      @thrust.system_or_exit 'agvtool bump -all'
    end
  end

  namespace :version do
    desc 'Bumps the major marketing version in (major.minor.patch)'
    task :major do
      @thrust.update_version(:major)
    end

    desc 'Bumps the minor marketing version in (major.minor.patch)'
    task :minor do
      @thrust.update_version(:minor)
    end

    desc 'Bumps the patch marketing version in (major.minor.patch)'
    task :patch do
      @thrust.update_version(:patch)
    end
  end
end

desc 'Build custom configuration'
task :build_configuration, :configuration do |task_name, args|
  build_prefix = @thrust.build_prefix_for(args[:configuration])
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration '#{args[:configuration]}' -sdk iphoneos clean", @thrust.output_file("clean")
  @thrust.kill_simulator
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -target #{@thrust.config['app_name']} -configuration '#{args[:configuration]}' -sdk iphoneos build", @thrust.output_file(args[:configuration])
  @thrust.system_or_exit "/usr/bin/xcrun -sdk iphoneos PackageApplication -v '#{build_prefix}.app' -o '#{build_prefix}.ipa' --sign '#{@thrust.config['identity']}'"
  @thrust.system_or_exit "zip -r -T -y '#{build_prefix}.app.dSYM.zip' '#{build_prefix}.app.dSYM'"
end

namespace :testflight do
  @thrust.config['distributions'].each do |task_name, info|
    desc "Deploy build to testflight #{info['team']} team (use NOTIFY=false to prevent team notification)"
    task task_name do
      Rake::Task["testflight:deploy"].invoke(info['token'], info['default_list'], info['configuration'])
    end
  end

  task :deploy, :team, :distribution_list, :configuration do |task, args|
    build_prefix = @thrust.build_prefix_for(args[:configuration])
    Rake::Task["bump:build"].invoke
    Rake::Task["build_configuration"].invoke(args[:configuration])
    print "Deploy Notes: "
    message = STDIN.gets
    message += "\n" + `git log HEAD^..HEAD`
    message_file = Tempfile.new("deploy_notes")
    File.open(message_file, 'w') {|f| f.write(message) }

    @thrust.system_or_exit "curl http://testflightapp.com/api/builds.json\
      -F file=@#{build_prefix}.ipa\
      -F dsym=@#{build_prefix}.app.dSYM.zip\
      -F api_token='#{@thrust.config['api_token']}'\
      -F team_token='#{args[:team]}'\
      -F notes=@#{message_file.path}\
      -F notify=#{(ENV['NOTIFY'] || 'true').downcase.capitalize}\
      #{"-F distribution_lists='#{args[:distribution_list]}'" if args[:distribution_list]}"
  end
end
