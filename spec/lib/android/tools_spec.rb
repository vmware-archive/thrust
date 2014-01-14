require 'spec_helper'

describe Thrust::Android::Tools do
  describe 'initialization' do
    it 'sets a default value for android home if it is not set' do
      ENV.delete('ANDROID_HOME')

      Thrust::Android::Tools.new(StringIO.new)

      expect(ENV['ANDROID_HOME']).to eq('/usr/local/opt/android-sdk')
    end
  end
end
