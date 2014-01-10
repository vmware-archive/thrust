require 'spec_helper'

describe Thrust::Git do
  let(:out) { StringIO.new }
  subject(:git) { Thrust::Git.new(out) }

  describe '#ensure_clean' do
    it 'makes sure that the working directory is clean' do
      Thrust::Executor.should_receive(:system_or_exit).with('git diff-index --quiet HEAD')
      git.ensure_clean
    end

    context 'when IGNORE GIT is set' do
      before { ENV['IGNORE_GIT'] = 'yep' }
      after { ENV.delete('IGNORE_GIT') }

      it 'prints a warning message' do
        git.ensure_clean
        out.string.should include 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'
      end

      it "doesn't check if the working directory is clean" do
        Thrust::Executor.should_not_receive(:system_or_exit).with('git diff-index --quiet HEAD')
        git.ensure_clean
      end
    end
  end
end
