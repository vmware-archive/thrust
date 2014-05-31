require 'spec_helper'

describe Thrust::IOS::Synx do
  describe '.initialize' do
    it 'requires either a project_name' do
      expect { Thrust::IOS::Synx.new }.to raise_error
    end
  end

  describe '#run' do
    it "runs synx on the project" do
      thrust_executor = Thrust::FakeExecutor.new
      allow(thrust_executor).to receive(:system_or_exit)
      Thrust::IOS::Synx.new("MyProject", thrust_executor).run
      expect(thrust_executor).to have_received(:system_or_exit).with("synx MyProject.xcodeproj")
    end
  end
end
