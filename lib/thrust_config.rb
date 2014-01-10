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

  def system_or_exit(cmd, stdout = nil)
    STDERR.puts "Executing #{cmd}"
    cmd += " >#{stdout}" if stdout
    system(cmd) or raise '******** Build failed ********'
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
      cmd = "agvtool what-marketing-version -terse | head -n1 |cut -f2 -d\="
      STDERR.puts "Executing #{cmd}"
      version = `#{cmd}`

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
