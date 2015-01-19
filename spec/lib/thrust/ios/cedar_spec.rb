require 'spec_helper'

describe Thrust::IOS::Cedar do
  let(:build_configuration) { 'build_configuration' }
  let(:build_sdk) { 'os' }
  let(:executable_name) { 'AwesomeExecutable' }
  let(:device_name) { 'device-name' }
  let(:os_version) { 'os-version' }
  let(:build_dir) { 'build_dir' }
  let(:out) { StringIO.new }
  let(:ios_sim_path) { '/path/to/my/ios-sim' }
  let(:timeout) { '45' }
  let(:thrust_executor) { double(Thrust::Executor) }

  subject { Thrust::IOS::Cedar.new(out, thrust_executor) }

  describe '#run' do
    before do
      allow(thrust_executor).to receive(:check_command_for_failure).and_return(true)
    end

    def run_cedar
      subject.run(executable_name, build_configuration, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path)
    end

    it 'launches the spec executable with ios-sim' do
      success = run_cedar

      expect(success).to eq true

      expected_command = %Q[/path/to/my/ios-sim launch build_dir/build_configuration-os/AwesomeExecutable.app --devicetypeid 'com.apple.CoreSimulator.SimDeviceType.device-name, os-version' --timeout 45 --setenv CFFIXED_USER_HOME=/tmp --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter]
      expect(thrust_executor).to have_received(:check_command_for_failure).with(expected_command)
    end

    it 'returns false when the command fails' do
      allow(thrust_executor).to receive(:check_command_for_failure).and_return(false)

      expect(run_cedar).to be_falsey
    end

    it 'passes timeout through to executor' do
      run_cedar
      expect(thrust_executor).to have_received(:check_command_for_failure).with(/--timeout 45/)
    end

    context 'with macosx as the build_sdk' do
      let(:build_sdk) { 'macosx' }

      it 'should (safely) pass thrust the build path as an env variable' do
        run_cedar

        expect(thrust_executor).to have_received(:check_command_for_failure).with('"build_dir/build_configuration/AwesomeExecutable"', {'DYLD_FRAMEWORK_PATH' => '"build_dir/build_configuration"'})
      end
    end

    describe 'when no ios_sim_path is provided' do
      let(:ios_sim_path) { nil }

      it 'defaults to system-installed ios-sim' do
        run_cedar

        expect(thrust_executor).to have_received(:check_command_for_failure).with(/ios-sim/)
      end
    end

    describe 'when no timeout is provided' do
      let(:timeout) { nil }

      it 'defaults to 30' do
        run_cedar

        expect(thrust_executor).to have_received(:check_command_for_failure).with(/--timeout 30/)
      end
    end
  end
end
