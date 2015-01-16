require_relative 'deployment_target'
require_relative 'ios_spec_target'
require_relative 'testflight_credentials'

module Thrust
  class AppConfig
    attr_reader :app_name,
                :deployment_targets,
                :ios_distribution_certificate,
                :ios_sim_path,
                :ios_spec_targets,
                :project_name,
                :testflight,
                :thrust_version,
                :workspace_name,
                :path_to_xcodeproj,
                :spec_directories,
                :build_directory,
                :project_root

    def initialize(attributes)
      @app_name = attributes['app_name']
      @deployment_targets = generate_deployment_targets(attributes['deployment_targets'])
      @ios_distribution_certificate = attributes['ios_distribution_certificate']
      @ios_sim_path = attributes['ios_sim_path']
      @ios_spec_targets = generate_ios_spec_targets(attributes['ios_spec_targets'])
      @spec_directories = generate_spec_directories(attributes['spec_directories'])
      @project_name = attributes['project_name']
      @testflight = generate_testflight_credentials(attributes['testflight'])
      @thrust_version = attributes['thrust_version'].to_s
      @workspace_name = attributes['workspace_name']
      @path_to_xcodeproj = attributes['path_to_xcodeproj']
      @build_directory = attributes['build_directory']
      @project_root = attributes['project_root']
    end

    private

    def generate_ios_spec_targets(ios_spec_targets_hash)
      return {} if ios_spec_targets_hash.nil?

      ios_spec_targets_hash.inject({}) do |existing, (key, value)|
        existing[key] = IOSSpecTarget.new(value)
        existing
      end
    end

    def generate_spec_directories(spec_directories)
      return [] if spec_directories.nil?

      spec_directories.map do |sd|
        File.expand_path(File.join(Dir.pwd, sd))
      end
    end

    def generate_deployment_targets(deployment_targets_hash)
      return {} if deployment_targets_hash.nil?

      deployment_targets_hash.inject({}) do |existing, (key, value)|
        existing[key] = DeploymentTarget.new(value)
        existing
      end
    end

    def generate_testflight_credentials(testflight_credentials_hash)
      return if testflight_credentials_hash.nil?

      TestflightCredentials.new(testflight_credentials_hash)
    end
  end
end
