class Thrust::Config
  attr_reader :project_root, :app_config, :build_dir
  THRUST_VERSION = 0.2
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

  private

  def verify_configuration(config)
    config['thrust_version'] ||= 0
    if config['thrust_version'] != THRUST_VERSION
      fail "Invalid configuration. Have you updated thrust recently? Your thrust.yml specifies version #{config['thrust_version']}, but thrust is at version #{THRUST_VERSION}. See README for details.".red
    end
  end
end
