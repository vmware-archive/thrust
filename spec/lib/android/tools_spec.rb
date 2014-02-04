require 'spec_helper'

describe Thrust::Android::Tools do
  let (:thrust_executor) { Thrust::FakeExecutor.new }
  subject { Thrust::Android::Tools.new(thrust_executor, StringIO.new) }

  describe 'building a signed release' do
    context 'when android home is not set' do
      before do
        ENV.delete('ANDROID_HOME')
      end

      context 'when /usr/local/opt/android-sdk does not exist' do
        it 'tells the user to install android' do
          expect {
            subject.build_signed_release
          }.to raise_exception('**********Android is not installed. Run `brew install android`.**********')
        end
      end

      context 'when /usr/local/opt/android-sdk exists and maven succeeds' do
        before do
          FileUtils.mkdir_p('/usr/local/opt/android-sdk')
          FileUtils.mkpath('target/example-signed-aligned.apk')
        end

        it 'sets it as the default value for android home' do
          subject.build_signed_release
          expect(ENV['ANDROID_HOME']).to eq('/usr/local/opt/android-sdk')
        end

        it 'tells maven to run' do
          subject.build_signed_release
          expect(thrust_executor.system_or_exit_history.last).to eq({
            cmd: 'mvn clean package -Prelease',
            output_file: nil
          })
        end
      end

      context 'when /usr/local/opt/android-sdk exists and maven fails' do
        before do
          FileUtils.mkdir_p('/usr/local/opt/android-sdk')
          FileUtils.rmdir('target/example-signed-aligned.apk')
        end

        it 'raises an error' do
          expect { subject.build_signed_release }.to raise_exception 'Signed APK was not generated'
        end
      end
    end

    context 'when android home is set' do
      before do
        ENV['ANDROID_HOME'] = '/usr/local/opt/android-sdk'
        FileUtils.mkpath('target/example-signed-aligned.apk')
      end

      it 'tells maven to run' do
        subject.build_signed_release
        expect(thrust_executor.system_or_exit_history.last).to eq({
          cmd: 'mvn clean package -Prelease',
          output_file: nil
        })
      end
    end
  end
end
