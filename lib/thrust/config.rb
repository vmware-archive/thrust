require 'colorize'
require_relative 'app_config'
require 'yaml'

module Thrust
  class Config
    attr_reader :project_root, :app_config, :build_dir

    THRUST_VERSION = '0.3'
    THRUST_ROOT = File.expand_path('../..', __FILE__)

    def self.make(relative_project_root, config_file)
      begin
        config_file_contents = YAML.load_file(config_file)
      rescue Errno::ENOENT
        puts ""
        puts "  Missing thrust.yml. Create by running:\n".red
        puts "      cp thrust.example.yml thrust.yml".blue
        exit 1
      rescue Psych::SyntaxError
        puts ""
        puts "  Malformed thrust.yml.".red
        exit 1
      end
      new(relative_project_root, config_file_contents)
    end

    def initialize(relative_project_root, config)
      @project_root = File.expand_path(relative_project_root)
      @build_dir = File.join(project_root, 'build')
      @app_config = Thrust::AppConfig.new(config)
      verify_configuration
    end

    private

    def verify_configuration
      if @app_config.thrust_version != THRUST_VERSION
        fail "Invalid configuration. Have you updated thrust recently? Your thrust.yml specifies an out-of-date version, and thrust is at version: #{THRUST_VERSION}. See README for details.".red
      end
    end
  end
end
