require 'spec_helper'

describe Thrust::ExecutionHelper do
  describe '#capture_status_from_command' do
    it 'returns true when the command succeeds' do
      subject.capture_status_from_command('sh -c "exit 0"').should == true
    end

    it 'returns false when the command fails' do
      subject.capture_status_from_command('sh -c "exit 1"').should == false
    end
  end

  describe '#capture_status_and_output_from_command' do
    it 'returns the output and the return status of the command when the command succeeds' do
      subject.capture_status_and_output_from_command('echo foo').should == [true, "foo\n"]
    end

    it 'returns the output and the return status of the command when the command fails' do
      subject.capture_status_and_output_from_command('echo foo; exit 1').should == [false, "foo\n"]
    end
  end
end
