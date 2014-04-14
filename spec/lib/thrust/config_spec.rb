require 'spec_helper'

describe Thrust::Config do
  describe 'initializing' do
    it 'initializes an app config based on a hash' do
      ios_spec_targets = {
        'specs' => {
          'type' => 'foo',
          'scheme' => 'some-scheme',
          'target' => 'some-target'
        }
      }

      config_hash = {
        'thrust_version' => Thrust::Config::THRUST_VERSION,
        'ios_spec_targets' => ios_spec_targets
      }

      config = Thrust::Config.new('/', config_hash)

      target = config.app_config.ios_spec_targets['specs']
      expect(target.type).to eq('foo')
      expect(target.scheme).to eq('some-scheme')
      expect(target.target).to eq('some-target')
    end
  end
end
