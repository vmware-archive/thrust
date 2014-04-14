module Thrust
  class IOSSpecTarget
    attr_reader :build_configuration,
                :build_sdk,
                :device,
                :runtime_sdk,
                :scheme,
                :target,
                :type

    def initialize(attributes)
      @build_configuration = attributes['build_configuration']
      @build_sdk = attributes['build_sdk'] || 'iphonesimulator'
      @device = attributes['device'] || 'iphone'
      @runtime_sdk = attributes['runtime_sdk']
      @scheme = attributes['scheme']
      @target = attributes['target']
      @type = attributes['type'] || 'app'
    end
  end
end
