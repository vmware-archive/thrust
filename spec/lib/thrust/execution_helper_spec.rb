require 'spec_helper'

describe Thrust::ExecutionHelper do
  describe '#capture_status_from_command' do
    it 'returns true when the command succeeds' do
      subject.capture_status_from_command('sh -c "exit 0"').should == true
    end

    it 'returns false when the command fails' do
      subject.capture_status_from_command('sh -c "exit 1"').should == false
    end

    it 'uses the passed-in env vars' do
      subject.capture_status_from_command('sh -c "if [[ -z $VAR ]]; then exit 1; else exit 0; fi"', {'VAR' => 'something'}).should == true
    end

    it 'unsets the variables upon completion' do
      subject.capture_status_from_command('sh -c "exit 0"', {'VAR' => 'something'})
      ENV['VAR'].should be_nil
    end

    it 'unsets the variables upon failed completion' do
      subject.capture_status_from_command('sh -c "exit 1"', {'VAR' => 'something'})
      ENV['VAR'].should be_nil
    end
  end

  describe '#capture_status_and_output_from_command' do
    it 'returns the output and the return status of the command when the command succeeds' do
      subject.capture_status_and_output_from_command('sh -c "echo foo"').should == {success: true, output: "foo\n"}
    end

    it 'returns the output and the return status of the command when the command fails' do
      subject.capture_status_and_output_from_command('sh -c "echo foo; exit 1"').should == {success: false, output: "foo\n"}
    end

    it 'uses the passed-in env vars' do
      subject.capture_status_and_output_from_command("sh -c 'if [[ -z $VAR ]]; then echo noooooo && exit 1; else echo yes && exit 0; fi'", {'VAR' => 'something'}).should == {success: true, output: "yes\n"}
    end

    it 'unsets the variables upon completion' do
      subject.capture_status_and_output_from_command('sh -c "exit 0"', {'VAR' => 'something'})
      ENV['VAR'].should be_nil
    end

    it 'unsets the variables upon failed completion' do
      subject.capture_status_and_output_from_command('sh -c "exit 1"', {'VAR' => 'something'})
      ENV['VAR'].should be_nil
    end
  end
end
