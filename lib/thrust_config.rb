class ThrustConfig
  attr_reader :project_root, :config, :build_dir
  THRUST_VERSION = 0.1

  def initialize(relative_project_root, config_file)
    @project_root = File.expand_path(relative_project_root)
    @build_dir = File.join(project_root, 'build')
    @config = YAML.load_file(config_file)
    verify_configuration(@config)
  end

  def verify_configuration(config)
    config['thrust_version'] ||= 0
    if config['thrust_version'] < THRUST_VERSION
      fail "Invalid configuration. Have you updated thrust recently? Your thrust.yml specifies version #{config['thrust_version']}, but thrust is at version #{THRUST_VERSION} see README for details."
    end
  end

  def build_prefix_for(configuration, suffix = nil)
    ["#{build_dir}/#{configuration}-iphoneos/#{config['app_name']}", suffix].compact.join('-')
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

  def grep_cmd_for_failure(cmd)
    1.times do
      STDERR.puts "Executing #{cmd} and checking for FAILURE"
      %x[#{cmd} > #{Dir.tmpdir}/cmd.out 2>&1]
      status = $?
      result = File.read("#{Dir.tmpdir}/cmd.out")
      if status.success?
        STDERR.puts 'Results:'
        STDERR.puts result
        if result.include?('FAILURE')
          exit(1)
        end
      elsif status == 256
        kill_simulator
        STDERR.puts "Retrying..."
        redo
      else
        STDERR.puts "Failed to launch: #{status}"
        exit(1)
      end
    end
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

  def kill_simulator
    system %q[killall -m -KILL "gdb"]
    system %q[killall -m -KILL "otest"]
    system %q[killall -m -KILL "iPhone Simulator"]
  end

  def update_version(release)
    run_git_with_message('Changes version to $(agvtool what-marketing-version -terse)') do
      version = run "agvtool what-marketing-version -terse | head -n1 |cut -f2 -d\="
      STDERR.puts "version !#{version}!"
      build_regex = %r{^(?<major>\d+)(\.(?<minor>\d+))?(\.(?<patch>\d+))$}
      if (match = build_regex.match(version))
        STDERR.puts "found match #{match.inspect}"
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
      STDERR.puts 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'
      block.call
    else
      STDERR.puts 'Checking for clean working tree...'
      system_or_exit 'git diff-index --quiet HEAD'
      STDERR.puts 'Checking that the master branch is up to date...'
      system_or_exit 'git fetch && git diff --quiet HEAD origin/master'
      block.call
      system_or_exit "git commit -am \"#{message}\" && git push origin head"
    end
  end
end
