require 'spec_helper'

describe Thrust::Executor do
  let(:execution_helper) { double(Thrust::ExecutionHelper) }
  let(:out) { StringIO.new }

  subject { Thrust::Executor.new(out, execution_helper) }

  describe '#system_or_exit' do
    context 'with an output file' do
      it 'echoes the command when the command runs successfully' do
        allow(execution_helper).to receive(:capture_status_from_command)
        .with('some-command > some-output-file', {})
        .and_return(true)

        subject.system_or_exit('some-command', 'some-output-file')

        expect(out.string).to include('Executing some-command')
      end

      it 'raises an error and echoes the command when the command fails' do
        allow(execution_helper).to receive(:capture_status_from_command)
        .with('some-command > some-output-file', {})
        .and_return(false)

        expect {
          subject.system_or_exit('some-command', 'some-output-file')
        }.to raise_error(Thrust::Executor::CommandFailed)

        expect(out.string).to include('Executing some-command')
      end
    end

    context 'without an output file' do
      it 'echoes the command when the command runs successfully' do
        allow(execution_helper).to receive(:capture_status_from_command).with('some-command', {}).and_return(true)

        subject.system_or_exit('some-command')

        expect(out.string).to include('Executing some-command')
      end

      it 'raises an error and echoes the command when the command fails' do
        allow(execution_helper).to receive(:capture_status_from_command).with('some-command', {}).and_return(false)

        expect {
          subject.system_or_exit('some-command')
        }.to raise_error(Thrust::Executor::CommandFailed)

        expect(out.string).to include('Executing some-command')
      end
    end

    context 'with env vars' do
      it 'tells the execution helper to runs the command with the env vars' do
        allow(execution_helper).to receive(:capture_status_from_command).and_return(true)

        subject.system_or_exit('yes', nil, {'FOO' => 'bar'})

        expect(execution_helper).to have_received(:capture_status_from_command).with('yes', {'FOO' => 'bar'})
      end
    end
  end

  describe '#capture_output_from_system' do
    it 'should return what the execution helper returns when the command runs successfully' do
      allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: 'foobar'})

      expect(subject.capture_output_from_system('does_foo')).to eq('foobar')
    end

    it 'should raise CommandFailed when the command fails' do
      allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: false, output: 'foobar'})

      expect {
        subject.capture_output_from_system('does_foo')
      }.to raise_error(Thrust::Executor::CommandFailed)
    end

    context 'with env vars' do
      it 'tells the execution helper to run the command with the env variables' do
        allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: 'foobar'})
        subject.capture_output_from_system('does_foo', {'FOO' => 'bar'})

        expect(execution_helper).to have_received(:capture_status_and_output_from_command).with('does_foo', {'FOO' => 'bar'})
      end
    end
  end

  describe '#check_command_for_failure' do
    describe 'the return value' do
      it 'should be true if Finished and no FAILURE or EXCEPTION' do
        output = 'Look ma, I Finished'
        allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: output})
        expect(subject.check_command_for_failure('does_bar')).to be_truthy
      end

      it 'should be false if no Finished' do
        output = 'Look ma, I never got done'
        allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: output})
        expect(subject.check_command_for_failure('does_bar')).to be_falsey
      end

      it 'should be false if Finished and FAILURE' do
        output = 'Look ma, I Finished and I am a FAILURE'
        allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: output})
        expect(subject.check_command_for_failure('does_bar')).to be_falsey
      end

      it 'should be false if Finished and EXCEPTION' do
        output = 'Look ma, I Finished and I am not EXCEPTIONAL'
        allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: output})
        expect(subject.check_command_for_failure('does_bar')).to be_falsey
      end
    end

    it 'should pipe the output into the output stream' do
      output = 'Look ma, I am pedantic'
      allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: output})
      subject.check_command_for_failure('does_bar')

      expect(out.string).to include(output)
    end

    it 'should pipe err into the output stream' do
      output = 'Finished with errouts'
      allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: output})
      subject.check_command_for_failure('does_foo')

      expect(execution_helper).to have_received(:capture_status_and_output_from_command).with('does_foo 2>&1', {})
    end

    context 'with env vars' do
      it 'tells the execution helper to run the command with the env variables' do
        output = 'Finished with vars'
        allow(execution_helper).to receive(:capture_status_and_output_from_command).and_return({success: true, output: output})
        subject.check_command_for_failure('does_foo', {'FOO' => 'bar'})

        expect(execution_helper).to have_received(:capture_status_and_output_from_command).with(an_instance_of(String), {'FOO' => 'bar'})
      end
    end
  end
end
