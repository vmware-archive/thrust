require_relative 'deployment_target'
require_relative 'spec_target'

module Thrust
  class AppConfig
    attr_reader :app_name,
                :deployment_targets,
                :distribution_certificate,
                :ios_sim_path,
                :spec_targets,
                :project_name,
                :thrust_version,
                :workspace_name,
                :path_to_xcodeproj,
                :spec_directories,
                :build_directory,
                :project_root

    def initialize(attributes)
      @build_directory = attributes['build_directory']
      @project_root = attributes['project_root']
      @app_name = attributes['app_name']
      @deployment_targets = generate_deployment_targets(attributes['deployment_targets'])
      @distribution_certificate = attributes['distribution_certificate']
      @ios_sim_path = attributes['ios_sim_path']
      @spec_targets = generate_spec_targets(attributes['spec_targets'])
      @spec_directories = generate_spec_directories(attributes['spec_directories'])
      @project_name = attributes['project_name']
      @thrust_version = attributes['thrust_version'].to_s
      @workspace_name = attributes['workspace_name']
      @path_to_xcodeproj = attributes['path_to_xcodeproj']
    end

    private

    def generate_spec_targets(spec_targets_hash)
      return {} if spec_targets_hash.nil?

      spec_targets_hash.inject({}) do |existing, (key, value)|
        existing[key] = SpecTarget.new(value)
        existing
      end
    end

    def generate_spec_directories(spec_directories)
      return [] if spec_directories.nil?

      spec_directories.map do |sd|
        File.expand_path(File.join(project_root, sd))
      end
    end

    def generate_deployment_targets(deployment_targets_hash)
      return {} if deployment_targets_hash.nil?

      deployment_targets_hash.inject({}) do |existing, (key, value)|
        existing[key] = DeploymentTarget.new(value)
        existing
      end
    end
  end
end
