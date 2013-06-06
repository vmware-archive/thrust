require 'yaml'

@thrust_config = YAML.load_file(Dir.pwd + 'thrust.yml')
@spec_config = @thrust_config['specs']

TESTFLIGHT_NOTIFICATION = ENV['NOTIFY'] || 'true'

PROJECT_ROOT = File.dirname(__FILE__)
BUILD_DIR = File.join(PROJECT_ROOT, "build")

def build_prefix_for(configuration)
  "#{BUILD_DIR}/#{configuration}-iphoneos/#{@thrust_config['app_name']}"
end

def sdk_dir
  "#{xcode_developer_dir}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator#{@spec_config['sdk']}.sdk"
end

# Xcode 4.3 stores its /Developer inside /Applications/Xcode.app, Xcode 4.2 stored it in /Developer
def xcode_developer_dir
  `xcode-select -print-path`.strip
end

def build_dir(effective_platform_name)
  File.join(BUILD_DIR, @spec_config['configuration'] + effective_platform_name)
end

def system_or_exit(cmd, stdout = nil)
  puts "Executing #{cmd}"
  cmd += " >#{stdout}" if stdout
  system(cmd) or raise '******** Build failed ********'
end

def run(cmd)
  puts "Executing #{cmd}"
  `#{cmd}`
end

def grep_cmd_for_failure(cmd)
  1.times do
    puts "Executing #{cmd} and checking for FAILURE"
    %x[#{cmd} > #{Dir.tmpdir}/cmd.out 2>&1]
    status = $?
    result = File.read("#{Dir.tmpdir}/cmd.out")
    if status.success?
      puts 'Results:'
      puts result
      if result.include?('FAILURE')
        exit(1)
      else
        exit(0)
      end
    elsif status == 256
      redo
    else
      puts "Failed to launch: #{status}"
      exit(1)
    end
  end
end

def with_env_vars(env_vars)
  old_values = {}
  env_vars.each do |key,new_value|
    old_values[key] = ENV[key]
    ENV[key] = new_value
  end

  yield

  env_vars.each_key do |key|
    ENV[key] = old_values[key]
  end
end

def output_file(target)
  output_dir = if ENV['IS_CI_BOX']
    ENV['CC_BUILD_ARTIFACTS']
  else
    Dir.mkdir(BUILD_DIR) unless File.exists?(BUILD_DIR)
    BUILD_DIR
  end

  output_file = File.join(output_dir, "#{target}.output")
  puts "Output: #{output_file}"
  output_file
end

def kill_simulator
  system %q[killall -m -KILL "gdb"]
  system %q[killall -m -KILL "otest"]
  system %q[killall -m -KILL "iPhone Simulator"]
end

task :default => [:trim, :specs]

desc 'Trim whitespace'
task :trim do
  system_or_exit %Q[git status --short | awk '{if ($1 != "D" && $1 != "R") print $2}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
end

desc 'Clean all targets'
task :clean do
  system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration 'AdHoc' -sdk iphoneos clean", output_file("clean")
  system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration 'Debug' -sdk iphonesimulator clean", output_file("clean")
  system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration 'Release' -sdk iphonesimulator clean", output_file("clean")
end

namespace :bump do
  desc 'Bumps the build'
  task :build do
    run_git_with_message 'Bumped build to $(agvtool what-version -terse)' do
      system_or_exit 'agvtool bump -all'
    end
  end

  namespace :version do
    desc 'Bumps the major marketing version in (major.minor.patch)'
    task :major do
      update_version(:major)
    end

    desc 'Bumps the minor marketing version in (major.minor.patch)'
    task :minor do
      update_version(:minor)
    end

    desc 'Bumps the patch marketing version in (major.minor.patch)'
    task :patch do
      update_version(:patch)
    end
  end
end

def update_version(release)
  run_git_with_message('Changes version to $(agvtool what-marketing-version -terse)') do
    version = run "agvtool what-marketing-version -terse | head -n1 |cut -f2 -d\="
    puts "version !#{version}!"
    build_regex = %r{^(?<major>\d+)(\.(?<minor>\d+))?(\.(?<patch>\d+))$}
    if (match = build_regex.match(version))
      puts "found match #{match.inspect}"
      v = {:major => match[:major].to_i, :minor => match[:minor].to_i, :patch => match[:patch].to_i}
      case(release)
        when :major then new_build_version(v[:major] + 1, 0, 0)
        when :minor then new_build_version(v[:major], v[:minor] + 1, 0)
        when :patch then new_build_version(v[:major], v[:minor], v[:patch] + 1)
        when :clear then new_build_version(v[:major], v[:minor], v[:patch])
      end
    else
      raise "Unknown version #{version} it should match major.minor.patch"
    end
  end
end

def new_build_version(major, minor, patch)
  version = [major, minor, patch].join(".")
  system_or_exit "agvtool new-marketing-version \"#{version}\""
end

def run_git_with_message(message, &block)
  if ENV['IGNORE_GIT']
    puts 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'
    block.call
  else
    puts 'Checking for clean working tree...'
    system_or_exit 'git diff-index --quiet HEAD'
    puts 'Checking that the master branch is up to date...'
    system_or_exit 'git fetch && git diff --quiet HEAD origin/master'
    block.call
    system_or_exit "git commit -am \"#{message}\" && git push origin head"
  end
end

desc 'Build custom configuration'
task :build_configuration, :configuration do |task_name, args|
  build_prefix = build_prefix_for(args[:configuration])
  system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration '#{args[:configuration]}' -sdk iphoneos clean", output_file("clean")
  kill_simulator
  system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -target #{@thrust_config['app_name']} -configuration '#{args[:configuration]}' -sdk iphoneos build", output_file(args[:configuration])
  system_or_exit "/usr/bin/xcrun -sdk iphoneos PackageApplication -v '#{build_prefix}.app' -o '#{build_prefix}.ipa' --sign '#{@thrust_config['identity']}'"
  system_or_exit "zip -r -T -y '#{build_prefix}.app.dSYM.zip' '#{build_prefix}.app.dSYM'"
end

namespace :testflight do
  @thrust_config['distributions'].each do |task_name, info|
    desc "Deploy build to testflight #{info['team']} team (use NOTIFY=false to prevent team notification)"
    task task_name do
      Rake::Task["testflight:deploy"].invoke(info['token'], info['default_list'], info['configuration'])
    end
  end

  task :deploy, :team, :distribution_list, :configuration do |task, args|
    build_prefix = build_prefix_for(args[:configuration])
    Rake::Task["bump:build"].invoke
    Rake::Task["build_configuration"].invoke(args[:configuration])
    system_or_exit "curl http://testflightapp.com/api/builds.json\
      -F file=@#{build_prefix}.ipa\
      -F dsym=@#{build_prefix}.app.dSYM.zip\
      -F api_token='#{@thrust_config['api_token']}'\
      -F team_token='#{args[:team]}'\
      -F notes='This build was uploaded via the upload API'\
      -F notify=#{TESTFLIGHT_NOTIFICATION.downcase.capitalize}\
      #{"-F distribution_lists='#{args[:distribution_list]}'" if args[:distribution_list]}"
  end
end

desc 'Build specs'
task :build_specs do
  kill_simulator
  system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -target #{@spec_config['target']} -configuration #{@spec_config['configuration']} -sdk iphonesimulator build", output_file("specs")
end

require 'tmpdir'

desc 'Run specs'
task :specs => :build_specs do
  grep_cmd_for_failure(%Q[Specs/bin/ios-sim launch #{File.join(build_dir("-iphonesimulator"), "#{@spec_config['target']}.app")} --sdk #{@spec_config['sdk']} --family iphone --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
end
