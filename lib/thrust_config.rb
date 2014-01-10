require File.expand_path('../xcrun', __FILE__)

class ThrustConfig
  attr_reader :project_root, :app_config, :build_dir
  THRUST_VERSION = 0.1
  THRUST_ROOT = File.expand_path('../..', __FILE__)

  def self.make(relative_project_root, config_file)
    begin
      config_file_contents = YAML.load_file(config_file)
    rescue
      puts "thrust: ERROR: Missing thrust.yml. Create by running:"
      puts "thrust: ERROR:    cp #{THRUST_ROOT}/lib/config/example.yml thrust.yml"
      exit 1
    end
    new(relative_project_root, config_file_contents, XCRun.new)
  end

  def initialize(relative_project_root, config, xcrun)
    @project_root = File.expand_path(relative_project_root)
    @build_dir = File.join(project_root, 'build')
    @app_config = config
    @xcrun = xcrun
    verify_configuration(@app_config)
  end

  def get_app_name_from(build_dir)
    full_app_path = Dir.glob(build_dir + '/*.app').first
    raise "No build product found!" unless full_app_path
    app_file_name = full_app_path.split('/').last
    return app_file_name.gsub('.app','')
  end

  def build_dir_for(configuration)
    "#{build_dir}/#{configuration}-iphoneos"
  end

  # Xcode 4.3 stores its /Developer inside /Applications/Xcode.app, Xcode 4.2 stored it in /Developer
  def xcode_developer_dir
    `xcode-select -print-path`.strip
  end

  def system_or_exit(cmd, stdout = nil)
    STDERR.puts "Executing #{cmd}"
    cmd += " >#{stdout}" if stdout
    system(cmd) or raise '******** Build failed ********'
  end

  def run(cmd)
    STDERR.puts "Executing #{cmd}"
    `#{cmd}`
  end

  def kill_simulator
    system %q[killall -m -KILL "gdb"]
    system %q[killall -m -KILL "otest"]
    system %q[killall -m -KILL "iPhone Simulator"]
  end

  def xcode_build(build_configuration, sdk, target)
    run_xcode('build', build_configuration, sdk, target)
  end

  def xcode_build_configurations
    output = `xcodebuild -project #{app_config['project_name']}.xcodeproj -list`
    match = /Build Configurations:(.+?)\n\n/m.match(output)
    if match
      match[1].strip.split("\n").map { |line| line.strip }
    else
      []
    end
  end

  def xcode_package(build_configuration)
    build_dir = build_dir_for(build_configuration)
    app_name = get_app_name_from(build_dir)
    xcrun.call(build_dir, app_name, app_config['identity'])
  end

  def run_cedar(build_configuration, target, sdk, os, device)
    return_code = 1
    if os == 'macosx'
      build_path = File.join(build_dir, build_configuration)
      app_dir = File.join(build_path, target)
      return_code = grep_cmd_for_failure("DYLD_FRAMEWORK_PATH=#{build_path.inspect} #{app_dir}")
    else
      binary = app_config['sim_binary']
      sim_dir = File.join(build_dir, "#{build_configuration}-#{os}", "#{target}.app")
      if binary =~ /waxim%/
        return_code = grep_cmd_for_failure(%Q[#{binary} -s #{sdk} -f #{device} -e CFFIXED_USER_HOME=#{Dir.tmpdir} -e CEDAR_HEADLESS_SPECS=1 -e CEDAR_REPORTER_CLASS=CDRDefaultReporter #{sim_dir}])
      elsif binary =~ /ios-sim$/
        return_code = grep_cmd_for_failure(%Q[#{binary} launch #{sim_dir} --sdk #{sdk} --family #{device} --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
      else
        puts "Unknown binary for running specs: '#{binary}'"
      end
    end
    return return_code
  end

  def update_version(release)
    run_git_with_message('Changes version to $(agvtool what-marketing-version -terse)') do
      version = run "agvtool what-marketing-version -terse | head -n1 |cut -f2 -d\="
      STDERR.puts "version !#{version}!"
      well_formed_version_regex = %r{^\d+(\.\d+)?(\.\d+)?$}
      if (match = well_formed_version_regex.match(version))
        STDERR.puts "found match #{match.inspect}"
        major, minor, patch = (version.split(".").map(&:to_i) + [0, 0, 0]).first(3)
        case(release)
        when :major then new_build_version(major + 1, 0, 0)
        when :minor then new_build_version(major, minor + 1, 0)
        when :patch then new_build_version(major, minor, patch + 1)
        when :clear then new_build_version(major, minor, patch)
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
      STDERR.puts 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'
      block.call
    else
      check_for_clean_working_tree
      STDERR.puts 'Checking that the master branch is up to date...'
      system_or_exit 'git fetch && git diff --quiet HEAD origin/master'
      block.call
      system_or_exit "git commit -am \"#{message}\" && git push origin head"
    end
  end

  def check_for_clean_working_tree
    if ENV['IGNORE_GIT']
      STDERR.puts 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'
    else
      STDERR.puts 'Checking for clean working tree...'
      system_or_exit 'git diff-index --quiet HEAD'
    end
  end

  private

  attr_reader :xcrun

  def run_xcode(build_command, build_configuration, sdk = nil, target = nil)
    system_or_exit(
      [
        "set -o pipefail &&",
        "xcodebuild",
        "-project #{app_config['project_name']}.xcodeproj",
        target ? "-target #{target}" : "-alltargets",
        "-configuration #{build_configuration}",
        sdk ? "-sdk #{sdk}" : "",
        "#{build_command}",
        "SYMROOT=#{@build_dir.inspect}",
        "2>&1",
        "| grep -v 'backing file'"
      ].join(" "),
        output_file("#{build_configuration}-#{build_command}")
    )
  end

  def output_file(target)
    output_dir = if ENV['IS_CI_BOX']
                   ENV['CC_BUILD_ARTIFACTS']
                 else
                   Dir.mkdir(build_dir) unless File.exists?(build_dir)
                   build_dir
                 end

    output_file = File.join(output_dir, "#{target}.output")
    STDERR.puts "Output: #{output_file}"
    output_file
  end

  def grep_cmd_for_failure(cmd)
    STDERR.puts "Executing #{cmd} and checking for FAILURE"
    result = %x[#{cmd} 2>&1]
    STDERR.puts "Results:"
    STDERR.puts result

    if !result.include?("Finished") || result.include?("FAILURE") || result.include?("EXCEPTION")
      return 1
    else
      return 0
    end
  end

  def verify_configuration(config)
    config['thrust_version'] ||= 0
    if config['thrust_version'] < THRUST_VERSION
      fail "Invalid configuration. Have you updated thrust recently? Your thrust.yml specifies version #{config['thrust_version']}, but thrust is at version #{THRUST_VERSION} see README for details."
    end
  end
end
