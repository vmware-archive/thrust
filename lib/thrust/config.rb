require 'colorize'
require_relative 'app_config'
require 'yaml'

module Thrust
  class Config
    class ConfigError < StandardError ; end
    class MissingConfigError < ConfigError ; end
    class MalformedConfigError < ConfigError ; end
    class InvalidVersionConfigError < ConfigError ; end

    THRUST_VERSION = '0.5'

    def self.load_configuration(relative_project_root, config_file, out = STDERR)
      begin
        config = YAML.load_file(config_file)
      rescue Errno::ENOENT
        out.puts ""
        out.puts "  Missing thrust.yml. Create by running:\n".red
        out.puts "      cp thrust.example.yml thrust.yml".blue
        raise MissingConfigError
      rescue Psych::SyntaxError
        out.puts ""
        out.puts "  Malformed thrust.yml.".red
        raise MalformedConfigError
      end

      project_root = File.expand_path(relative_project_root)
      config['project_root'] = project_root
      config['build_directory'] = File.join(project_root, 'build')

      app_config = Thrust::AppConfig.new(config)
      verify_configuration(app_config, out)

      app_config
    end

    private

    def self.verify_configuration(app_config, out)
      if app_config.thrust_version != THRUST_VERSION
        out.puts ''
        out.puts "  Invalid configuration. Have you updated thrust recently? Your thrust.yml specifies an out-of-date version, and thrust is at version: #{THRUST_VERSION}. See README for details.".red
        raise InvalidVersionConfigError
      end
    end
  end
end
