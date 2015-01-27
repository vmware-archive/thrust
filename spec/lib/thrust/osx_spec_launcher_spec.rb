require 'spec_helper'

describe Thrust::OSXSpecLauncher do
  let(:out) { StringIO.new }
  let(:thrust_executor) { double(Thrust::Executor) }

  subject { Thrust::OSXSpecLauncher.new(out, thrust_executor) }

  describe '#run' do
    before do
      allow(thrust_executor).to receive(:check_command_for_failure).and_return(true)
    end

    it 'launches the spec executable and checks for failure' do
      success = subject.run('AwesomeExecutable', 'build_configuration', 'build_dir')

      expect(success).to be_truthy
      expect(thrust_executor).to have_received(:check_command_for_failure).with('"build_dir/build_configuration/AwesomeExecutable"', {'DYLD_FRAMEWORK_PATH' => '"build_dir/build_configuration"'})
    end

    it 'returns false when the command fails' do
      allow(thrust_executor).to receive(:check_command_for_failure).and_return(false)

      expect(subject.run('AwesomeExecutable', 'build_configuration', 'build_dir')).to be_falsey
    end
  end
end
