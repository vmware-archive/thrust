require_relative 'deployment_target'
require_relative 'ios_spec_target'
require_relative 'testflight_credentials'

module Thrust
  class AppConfig
    attr_reader :app_name,
                :deployment_targets,
                :ios_distribution_certificate,
                :ios_sim_binary,
                :ios_spec_targets,
                :project_name,
                :testflight,
                :thrust_version,
                :workspace_name

    def initialize(attributes)
      @app_name = attributes['app_name']
      @deployment_targets = generate_deployment_targets(attributes['deployment_targets'])
      @ios_distribution_certificate = attributes['ios_distribution_certificate']
      @ios_sim_binary = attributes['ios_sim_binary']
      @ios_spec_targets = generate_ios_spec_targets(attributes['ios_spec_targets'])
      @project_name = attributes['project_name']
      @testflight = generate_testflight_credentials(attributes['testflight'])
      @thrust_version = attributes['thrust_version'].to_s
      @workspace_name = attributes['workspace_name']
    end

    private

    def generate_ios_spec_targets(ios_spec_targets_hash)
      return {} if ios_spec_targets_hash.nil?

      ios_spec_targets_hash.inject({}) do |existing, (key, value)|
        existing[key] = IOSSpecTarget.new(value)
        existing
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
