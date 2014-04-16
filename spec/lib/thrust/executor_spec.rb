require 'spec_helper'

describe Thrust::Executor do
  let(:execution_helper) { double(Thrust::ExecutionHelper) }
  let(:out) { StringIO.new }

  subject { Thrust::Executor.new(out, execution_helper) }

  describe '#system_or_exit' do
    context 'with an output file' do
      it 'echoes the command when the command runs successfully' do
        execution_helper.stub(:capture_status_from_command)
        .with('some-command > some-output-file', {})
        .and_return(true)

        subject.system_or_exit('some-command', 'some-output-file')

        out.string.should include('Executing some-command')
      end

      it 'raises an error and echoes the command when the command fails' do
        execution_helper.stub(:capture_status_from_command)
        .with('some-command > some-output-file', {})
        .and_return(false)

        expect {
          subject.system_or_exit('some-command', 'some-output-file')
        }.to raise_error(Thrust::Executor::CommandFailed)

        out.string.should include('Executing some-command')
      end
    end

    context 'without an output file' do
      it 'echoes the command when the command runs successfully' do
        execution_helper.stub(:capture_status_from_command).with('some-command', {}).and_return(true)

        subject.system_or_exit('some-command')

        out.string.should include('Executing some-command')
      end

      it 'raises an error and echoes the command when the command fails' do
        execution_helper.stub(:capture_status_from_command).with('some-command', {}).and_return(false)

        expect {
          subject.system_or_exit('some-command')
        }.to raise_error(Thrust::Executor::CommandFailed)

        out.string.should include('Executing some-command')
      end
    end

    context 'with env vars' do
      it 'tells the execution helper to runs the command with the env vars' do
        execution_helper.stub(:capture_status_from_command).and_return(true)

        subject.system_or_exit('yes', nil, {'FOO' => 'bar'})

        execution_helper.should have_received(:capture_status_from_command).with('yes', {'FOO' => 'bar'})
      end
    end
  end

  describe '#capture_output_from_system' do
    it 'should return what the execution helper returns when the command runs successfully' do
      execution_helper.stub(:capture_status_and_output_from_command).and_return({success: true, output: 'foobar'})

      subject.capture_output_from_system('does_foo').should eq('foobar')
    end

    it 'should raise CommandFailed when the command fails' do
      execution_helper.stub(:capture_status_and_output_from_command).and_return({success: false, output: 'foobar'})

      expect {
        subject.capture_output_from_system('does_foo')
      }.to raise_error(Thrust::Executor::CommandFailed)
    end

    context 'with env vars' do
      it 'runs the command with the env variables' do
        execution_helper.stub(:capture_status_and_output_from_command).and_return({success: true, output: 'foobar'})
        subject.capture_output_from_system('does_foo', {'FOO' => 'bar'})

        execution_helper.should have_received(:capture_status_and_output_from_command).with('does_foo', {'FOO' => 'bar'})
      end
    end
  end

  describe '#check_command_for_failure' do
    describe 'the return value' do
      it 'should be true if Finished and no FAILURE or EXCEPTION' do
        output = 'Look ma, I Finished'
        execution_helper.stub(:capture_status_and_output_from_command).and_return({success: true, output: output})
        subject.check_command_for_failure('does_bar').should be_true
      end

      it 'should be false if no Finished' do
        output = 'Look ma, I never got done'
        execution_helper.stub(:capture_status_and_output_from_command).and_return({success: true, output: output})
        subject.check_command_for_failure('does_bar').should be_false
      end

      it 'should be false if Finished and FAILURE' do
        output = 'Look ma, I Finished and I am a FAILURE'
        execution_helper.stub(:capture_status_and_output_from_command).and_return({success: true, output: output})
        subject.check_command_for_failure('does_bar').should be_false
      end

      it 'should be false if Finished and EXCEPTION' do
        output = 'Look ma, I Finished and I am not EXCEPTIONAL'
        execution_helper.stub(:capture_status_and_output_from_command).and_return({success: true, output: output})
        subject.check_command_for_failure('does_bar').should be_false
      end
    end

    it 'should pipe the output into the output stream' do
      output = 'Look ma, I am pedantic'
      execution_helper.stub(:capture_status_and_output_from_command).and_return({success: true, output: output})
      subject.check_command_for_failure('does_bar')

      out.string.should include(output)
    end
  end
end
