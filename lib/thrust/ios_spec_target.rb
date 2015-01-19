module Thrust
  class IOSSpecTarget
    attr_reader :build_configuration,
                :build_sdk,
                :device,
                :device_name,
                :os_version,
                :scheme,
                :type,
                :timeout

    def initialize(attributes)
      @build_configuration = attributes['build_configuration']
      @build_sdk = attributes['build_sdk'] || 'iphonesimulator'
      @device = attributes['device'] || 'iphone'
      @device_name = attributes['device_name']
      @os_version = attributes['os_version']
      @scheme = attributes['scheme']
      @type = attributes['type'] || 'app'
      @timeout = attributes['timeout']
    end
  end
end
