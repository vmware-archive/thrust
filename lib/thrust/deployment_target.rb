module Thrust
  class DeploymentTarget
    attr_reader :distribution_list,
                :ios_build_configuration,
                :ios_provisioning_search_query,
                :ios_target,
                :note_generation_method,
                :notify,
                :versioning_method,
                :tag

    def initialize(attributes)
      @distribution_list = attributes['distribution_list']
      @ios_build_configuration = attributes['ios_build_configuration']
      @ios_provisioning_search_query = attributes['ios_provisioning_search_query']
      @ios_target = attributes['ios_target']
      @note_generation_method = attributes['note_generation_method']
      @notify = attributes['notify']
      @versioning_method = attributes['versioning_method']
      @tag = attributes['tag']
    end
  end
end
