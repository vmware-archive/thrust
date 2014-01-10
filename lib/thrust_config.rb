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
    new(relative_project_root, config_file_contents)
  end

  def initialize(relative_project_root, config)
    @project_root = File.expand_path(relative_project_root)
    @build_dir = File.join(project_root, 'build')
    @app_config = config
    verify_configuration(@app_config)
  end

  def system_or_exit(cmd, stdout = nil)
    STDERR.puts "Executing #{cmd}"
    cmd += " >#{stdout}" if stdout
    system(cmd) or raise '******** Build failed ********'
  end




  def update_version(release)
    Thrust::Git.new($stdout).commit_with_message('Changes version to $(agvtool what-marketing-version -terse)') do
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

  private


  def verify_configuration(config)
    config['thrust_version'] ||= 0
    if config['thrust_version'] < THRUST_VERSION
      fail "Invalid configuration. Have you updated thrust recently? Your thrust.yml specifies version #{config['thrust_version']}, but thrust is at version #{THRUST_VERSION} see README for details."
    end
  end
end
