require 'spec_helper'

describe Thrust::IOS::AgvTool do
  let(:thrust_executor) { Thrust::FakeExecutor.new }
  let(:out) { StringIO.new }
  let(:git) { double(Thrust::Git, checkout_file: 'checkout_file') }

  before do
    Thrust::Git.stub(:new).and_return(git)
  end

  describe '#change_build_number' do
    before do
      Thrust::IOS::AgvTool.new(thrust_executor, out).change_build_number(1000)
    end

    it 'instructs agvtool to change the version' do
      expect(thrust_executor.system_or_exit_history.last).to eq({
        cmd: 'agvtool new-version -all \'1000\'',
        output_file: nil
      })
    end

    it 'resets the .xcodeproj files via git' do
      expect(git).to have_received(:checkout_file).with('*.xcodeproj')
    end
  end
end
