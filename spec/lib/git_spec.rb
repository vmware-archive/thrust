require 'spec_helper'

describe Thrust::Git do
  let(:out) { StringIO.new }
  let(:thrust_executor) { Thrust::Executor.new }
  subject(:git) { Thrust::Git.new(thrust_executor, out) }

  describe '#ensure_clean' do
    it 'makes sure that the working directory is clean' do
      thrust_executor.should_receive(:system_or_exit).with('git diff-index --quiet HEAD')
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
        thrust_executor.should_not_receive(:system_or_exit).with('git diff-index --quiet HEAD')
        git.ensure_clean
      end
    end
  end

  describe '#commit_summary_for_last_deploy' do
    context 'when the target has been deployed previously' do
      it 'uses the commit message from that commit' do
        thrust_executor.should_receive(:capture_output_from_system).with('autotag list staging').and_return("7342334 ref/blah\nlatest_deployed_commit ref/blahblah")
        thrust_executor.should_receive(:capture_output_from_system).with("git log --oneline -n 1 latest_deployed_commit").and_return('summary')

        summary = git.commit_summary_for_last_deploy('staging')
        expect(summary).to include('summary')
      end
    end

    context 'when the target has not been deployed' do
      it 'says that the target has not been deployed' do
        thrust_executor.should_receive(:capture_output_from_system).with('autotag list staging').and_return("\n")
        summary = git.commit_summary_for_last_deploy('staging')
        expect(summary).to include('Never deployed')
      end
    end
  end

  describe '#generate_notes_for_deployment' do
    let(:temp_file) { File.new('notes', 'w+') }

    before do
      Tempfile.stub(:new).and_return(temp_file)
    end

    it 'generates deployment notes from the commit log history' do
      thrust_executor.should_receive(:capture_output_from_system).with('git rev-parse HEAD').and_return("latest_commit\n")
      thrust_executor.should_receive(:capture_output_from_system).with('autotag list staging').and_return("7342334 ref/blah\nlatest_deployed_commit")
      thrust_executor.should_receive(:system_or_exit).with('git log --oneline latest_deployed_commit...latest_commit', temp_file.path)

      notes = git.generate_notes_for_deployment('staging')
      expect(notes).to eq(temp_file.path)
    end

    context 'when there are no previously deployed commits' do
      it 'returns the commit message of just the latest commit' do
        thrust_executor.should_receive(:capture_output_from_system).with('git rev-parse HEAD').and_return("latest_commit\n")
        thrust_executor.should_receive(:capture_output_from_system).with('autotag list staging').and_return("\n")
        thrust_executor.should_receive(:capture_output_from_system).with("git log --oneline -n 1 latest_commit").and_return('summary')

        notes = git.generate_notes_for_deployment('staging')
        expect(notes).to eq(temp_file.path)

        file = File.open(temp_file.path)
        expect(file.read).to include('summary')
      end
    end
  end
end
