require 'spec_helper'

describe Thrust::IOS::Cedar do
  let(:build_configuration) { 'build_configuration' }
  let(:target) { 'target' }
  let(:runtime_sdk) { 'sdk' }
  let(:build_sdk) { 'os' }
  let(:device) { 'device' }
  let(:build_dir) { 'build_dir' }
  let(:out) { StringIO.new }
  let(:sim_binary) { 'ios-sim' }
  let(:thrust_executor) { double(Thrust::Executor) }

  subject { Thrust::IOS::Cedar.new(out, thrust_executor) }

  before do
    thrust_executor.stub(:check_command_for_failure)
  end

  describe 'run' do
    it 'returns true when the cmd works' do
      thrust_executor.stub(:check_command_for_failure).and_return(true)

      subject.run(build_configuration, target, runtime_sdk, build_sdk, device, build_dir, sim_binary).should be_true
    end

    it 'returns false when the cmd fails' do
      thrust_executor.stub(:check_command_for_failure).and_return(false)

      subject.run(build_configuration, target, runtime_sdk, build_sdk, device, build_dir, sim_binary).should be_false
    end

    context 'with macosx as the build_sdk' do
      let(:build_sdk) { 'macosx' }

      it 'should (safely) pass thrust the build path as an env variable' do
        thrust_executor.stub(:check_command_for_failure).and_return(false)
        subject.run(build_configuration, target, runtime_sdk, build_sdk, device, build_dir, sim_binary)

        build_path = File.join(build_dir, build_configuration)
        app_dir = File.join(build_path, target)
        thrust_executor.should have_received(:check_command_for_failure).with(app_dir.inspect, {'DYLD_FRAMEWORK_PATH' => build_path.inspect})
      end
    end

    context 'the binary is not valid' do
      let(:sim_binary) { 'invalid-binary' }

      it 'returns false when the binary is not recognized' do
        subject.run(build_configuration, target, runtime_sdk, build_sdk, device, build_dir, sim_binary).should be_false

        expect(out.string).to include('Unknown binary for running specs')
      end
    end
  end
end
