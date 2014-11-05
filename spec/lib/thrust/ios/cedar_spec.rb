require 'spec_helper'

describe Thrust::IOS::Cedar do
  let(:build_configuration) { 'build_configuration' }
  let(:target) { 'target' }
  let(:build_sdk) { 'os' }
  let(:device_name) { 'device-name' }
  let(:os_version) { 'os-version' }
  let(:build_dir) { 'build_dir' }
  let(:out) { StringIO.new }
  let(:ios_sim_path) { '/path/to/my/ios-sim' }
  let(:timeout) { '45' }
  let(:thrust_executor) { double(Thrust::Executor) }

  subject { Thrust::IOS::Cedar.new(out, thrust_executor) }

  describe 'run' do
    it 'returns true when the cmd works' do
      thrust_executor.stub(:check_command_for_failure).and_return(true)

      subject.run(build_configuration, target, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path).should be_true
      expect(thrust_executor).to have_received(:check_command_for_failure).with(/com.apple.CoreSimulator.SimDeviceType.device-name, os-version/)
    end

    it 'returns false when the cmd fails' do
      thrust_executor.stub(:check_command_for_failure).and_return(false)

      subject.run(build_configuration, target, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path).should be_false
    end

    it 'passes timeout through to executor' do
      thrust_executor.stub(:check_command_for_failure)

      subject.run(build_configuration, target, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path)
      expect(thrust_executor).to have_received(:check_command_for_failure).with(/--timeout 45/)
    end

    context 'with macosx as the build_sdk' do
      let(:build_sdk) { 'macosx' }

      it 'should (safely) pass thrust the build path as an env variable' do
        thrust_executor.stub(:check_command_for_failure).and_return(false)
        subject.run(build_configuration, target, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path)

        build_path = File.join(build_dir, build_configuration)
        app_dir = File.join(build_path, target)
        thrust_executor.should have_received(:check_command_for_failure).with(app_dir.inspect, {'DYLD_FRAMEWORK_PATH' => build_path.inspect})
      end
    end

    describe 'when no ios_sim_path is provided' do
      let(:ios_sim_path) { nil }

      it 'defaults to system-installed ios-sim' do
        thrust_executor.stub(:check_command_for_failure)
        subject.run(build_configuration, target, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path)

        expect(thrust_executor).to have_received(:check_command_for_failure).with(/ios-sim/)
      end
    end

    describe 'when no timeout is provided' do
      let(:timeout) { nil }

      it 'defaults to 30' do
        thrust_executor.stub(:check_command_for_failure)
        subject.run(build_configuration, target, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path)

        expect(thrust_executor).to have_received(:check_command_for_failure).with(/--timeout 30/)
      end
    end
  end
end
