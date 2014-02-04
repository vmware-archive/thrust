require 'spec_helper'

describe Thrust::IOS::Cedar do
  let(:build_configuration) { 'build_configuration' }
  let(:target) { 'target' }
  let(:sdk) { 'sdk' }
  let(:os) { 'os' }
  let(:device) { 'device' }
  let(:build_dir) { 'build_dir' }
  let(:out) { StringIO.new }
  let(:sim_binary) { 'ios-sim' }
  let(:thrust_executor) { Thrust::Executor.new }
  let(:cedar) { Thrust::IOS::Cedar.new(thrust_executor) }

  subject { cedar.run(out, build_configuration, target, sdk, os, device, build_dir, sim_binary) }

  before do
    thrust_executor.stub(:check_command_for_failure)
  end

  describe 'run' do
    it 'returns true when the cmd works' do
      thrust_executor.stub(:check_command_for_failure).and_return(true)

      expect(subject).to be_true
    end

    it 'returns false when the cmd fails' do
      thrust_executor.stub(:check_command_for_failure).and_return(false)

      expect(subject).to be_false
    end

    context 'the binary is not valid' do
      let(:sim_binary) { 'invalid-binary' }

      it 'returns false when the binary is not recognized' do
        expect(subject).to be_false
        expect(out.string).to include('Unknown binary for running specs')
      end
    end
  end
end
