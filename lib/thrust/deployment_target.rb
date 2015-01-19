module Thrust
  class DeploymentTarget
    attr_reader :distribution_list,
                :build_configuration,
                :provisioning_search_query,
                :target,
                :note_generation_method,
                :notify,
                :versioning_method,
                :tag

    def initialize(attributes)
      @distribution_list = attributes['distribution_list']
      @build_configuration = attributes['build_configuration']
      @provisioning_search_query = attributes['provisioning_search_query']
      @target = attributes['target']
      @note_generation_method = attributes['note_generation_method']
      @notify = attributes['notify']
      @versioning_method = attributes['versioning_method']
      @tag = attributes['tag']
    end
  end
end
