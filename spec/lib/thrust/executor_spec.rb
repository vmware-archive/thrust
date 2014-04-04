require 'spec_helper'

describe Thrust::Executor do
  let(:execution_helper) { double(Thrust::ExecutionHelper) }
  let(:out) { StringIO.new }

  subject { Thrust::Executor.new(out, execution_helper) }

  describe '#system_or_exit' do
    context 'with an output file' do
      it 'echoes the command when the command runs successfully' do
        execution_helper.stub(:capture_status_from_command)
        .with('some-command > some-output-file')
        .and_return(true)

        subject.system_or_exit('some-command', 'some-output-file')

        out.string.should include('Executing some-command')
      end

      it 'raises an error and echoes the command when the command fails' do
        execution_helper.stub(:capture_status_from_command)
        .with('some-command > some-output-file')
        .and_return(false)

        expect {
          subject.system_or_exit('some-command', 'some-output-file')
        }.to raise_error(Thrust::Executor::CommandFailed)

        out.string.should include('Executing some-command')
      end
    end

    context 'without an output file' do
      it 'echoes the command when the command runs successfully' do
        execution_helper.stub(:capture_status_from_command).with('some-command').and_return(true)

        subject.system_or_exit('some-command')

        out.string.should include('Executing some-command')
      end

      it 'raises an error and echoes the command when the command fails' do
        execution_helper.stub(:capture_status_from_command).with('some-command').and_return(false)

        expect {
          subject.system_or_exit('some-command')
        }.to raise_error(Thrust::Executor::CommandFailed)

        out.string.should include('Executing some-command')
      end
    end
  end
end
