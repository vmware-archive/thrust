require 'spec_helper'

describe Thrust::Cedar do
  let(:build_configuration) { 'build_configuration' }
  let(:target) { 'target' }
  let(:sdk) { 'sdk' }
  let(:os) { 'os' }
  let(:device) { 'device' }
  let(:build_dir) { 'build_dir' }
  let(:app_config) { {'sim_binary' => 'ios-sim'} }

  subject { Thrust::Cedar.run(build_configuration, target, sdk, os, device, build_dir, app_config) }

  describe 'run' do

    it 'returns true when the cmd works' do
      Thrust::Cedar.stub(:`).and_return('Finished')

      expect(subject).to be_true
    end

    it 'returns false when the cmd fails' do
      Thrust::Cedar.stub(:`).and_return('FAILURE')

      expect(subject).to be_false
    end

    context 'the binary is not valid' do
      before { app_config['sim_binary'] = 'invalid-binary' }
      it 'returns false when the binary is not recognized' do
        expect(subject).to be_false
      end
    end

  end
  
end