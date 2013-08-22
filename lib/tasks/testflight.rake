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

namespace :testflight do
  @thrust.config['distributions'].each do |task_name, info|
    desc "Deploy build to testflight #{info['team']} team (use NOTIFY=false to prevent team notification)"
    task task_name do
      @team_token = info['token']
      @distribution_list = info['default_list']
      @configuration = info['configuration']
      @bumps_build_number = info['increments_build_number'].nil? ? true : info['increments_build_number']
      @configured = true
      Rake::Task["testflight:deploy"].invoke
    end
  end

  task :deploy do
    raise "You need to run a distribution configuration." unless @configured
    team_token = @team_token
    distribution_list = @distribution_list
    build_configuration = @configuration
    build_dir = @thrust.build_dir_for(build_configuration)
    target = @thrust.config['app_name']

    if (@bumps_build_number)
      Rake::Task["bump:build"].invoke
    else
      @thrust.check_for_clean_working_tree
    end

    STDERR.puts "Cleaning..."
    @thrust.xcode_clean(build_configuration, 'iphoneos')
    @thrust.system_or_exit "rm -r #{build_dir} ; exit 0"
    STDERR.puts "Killing simulator..."
    @thrust.kill_simulator
    STDERR.puts "Building..."
    @thrust.xcode_build(build_configuration, 'iphoneos', target)

    app_name = @thrust.get_app_name_from(build_dir)

    STDERR.puts "Packaging..."
    @thrust.system_or_exit "/usr/bin/xcrun -sdk iphoneos PackageApplication -v '#{build_dir}/#{app_name}.app' -o '#{build_dir}/#{app_name}.ipa' --sign '#{@thrust.config['identity']}'"
    STDERR.puts "Zipping dSYM..."
    @thrust.system_or_exit "zip -r -T -y '#{build_dir}/#{app_name}.app.dSYM.zip' '#{build_dir}/#{app_name}.app.dSYM'"
    STDERR.puts "Done!"

    print "Deploy Notes: "
    message = STDIN.gets
    message += "\n" + `git log HEAD^..HEAD`
    message_file = Tempfile.new("deploy_notes")
    File.open(message_file, 'w') {|f| f.write(message) }

    @thrust.system_or_exit [
      "curl http://testflightapp.com/api/builds.json",
      "-F file=@#{build_dir}/#{app_name}.ipa",
      "-F dsym=@#{build_dir}/#{app_name}.app.dSYM.zip",
      "-F api_token='#{@thrust.config['api_token']}'",
      "-F team_token='#{team_token}'",
      "-F notes=@#{message_file.path}",
      "-F notify=#{(ENV['NOTIFY'] || 'true').downcase.capitalize}",
      ("-F distribution_lists='#{distribution_list}'" if distribution_list)
    ].compact.join(' ')
  end
end
