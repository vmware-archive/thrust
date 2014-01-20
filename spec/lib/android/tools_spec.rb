require 'spec_helper'

describe Thrust::Android::Tools do
  describe 'initialization' do
    context 'when android home is not set' do
      before do
        ENV.delete('ANDROID_HOME')
      end

      context 'when /usr/local/opt/android-sdk does not exist' do
        it 'tells the user to install android' do
          expect {
            Thrust::Android::Tools.new(StringIO.new)
          }.to raise_exception('**********Android is not installed. Run `brew install android`.**********')
        end
      end

      context 'when /usr/local/opt/android-sdk exists' do
        before do
          FileUtils.mkdir_p('/usr/local/opt/android-sdk')
        end

        it 'sets it as the default value for android home' do
          Thrust::Android::Tools.new(StringIO.new)
          expect(ENV['ANDROID_HOME']).to eq('/usr/local/opt/android-sdk')
        end
      end
    end
  end
end
