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
task :build, :configuration do |task_name, args|
  build_dir = @thrust.build_dir_for(args[:configuration])
  STDERR.puts "Cleaning..."
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -alltargets -configuration '#{args[:configuration]}' -sdk iphoneos clean", @thrust.output_file("clean")
  @thrust.system_or_exit "rm -r #{build_dir} ; exit 0"
  STDERR.puts "Killing simulator..."
  @thrust.kill_simulator
  STDERR.puts "Building..."
  @thrust.system_or_exit "xcodebuild -project #{@thrust.config['project_name']}.xcodeproj -target #{@thrust.config['app_name']} -configuration '#{args[:configuration]}' -sdk iphoneos build", @thrust.output_file(args[:configuration])
end

desc 'Build custom configuration'
task :package, :build_dir, :app_name do |task_name, args|
  build_dir = args[:build_dir]
  app_name = args[:app_name]

  STDERR.puts "Packaging..."
  @thrust.system_or_exit "/usr/bin/xcrun -sdk iphoneos PackageApplication -v '#{build_dir}/#{app_name}.app' -o '#{build_dir}/#{app_name}.ipa' --sign '#{@thrust.config['identity']}'"
  STDERR.puts "Zipping dSYM..."
  @thrust.system_or_exit "zip -r -T -y '#{build_dir}/#{app_name}.app.dSYM.zip' '#{build_dir}/#{app_name}.app.dSYM'"
  STDERR.puts "Done!"
end

namespace :testflight do
  @thrust.config['distributions'].each do |task_name, info|
    desc "Deploy build to testflight #{info['team']} team (use NOTIFY=false to prevent team notification)"
    task task_name do
      Rake::Task["testflight:deploy"].invoke(info['token'], info['default_list'], info['configuration'])
    end
  end

  task :deploy, :team_token, :distribution_list, :configuration do |task, args|
    build_dir = @thrust.build_dir_for(args[:configuration])
    Rake::Task["bump:build"].invoke
    Rake::Task["build"].invoke(args[:configuration])
    app_name = @thrust.get_app_name_from(build_dir)
    Rake::Task["package"].invoke(build_dir, app_name)
    print "Deploy Notes: "
    message = STDIN.gets
    message += "\n" + `git log HEAD^..HEAD`
    message_file = Tempfile.new("deploy_notes")
    File.open(message_file, 'w') {|f| f.write(message) }

    @thrust.system_or_exit "curl http://testflightapp.com/api/builds.json\
      -F file=@#{build_dir}/#{app_name}.ipa\
      -F dsym=@#{build_dir}/#{app_name}.app.dSYM.zip\
      -F api_token='#{@thrust.config['api_token']}'\
      -F team_token='#{args[:team_token]}'\
      -F notes=@#{message_file.path}\
      -F notify=#{(ENV['NOTIFY'] || 'true').downcase.capitalize}\
      #{"-F distribution_lists='#{args[:distribution_list]}'" if args[:distribution_list]}"
  end
end
