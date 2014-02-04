require 'spec_helper'

describe Thrust::Testflight do
  let(:out) { StringIO.new }
  let(:input) { StringIO.new }
  let(:api_token) { 'api_token' }
  let(:team_token) { 'team_token' }
  let(:git) { double(Thrust::Git, generate_notes_for_deployment: 'notes') }
  let(:thrust_executor) { Thrust::Executor.new }
  subject(:testflight) { Thrust::Testflight.new(thrust_executor, out, input, api_token, team_token) }

  before do
    Thrust::Git.stub(:new).and_return(git)
  end

  describe '#upload' do
    let(:build_directory) { 'build' }
    let(:app_name) { 'AppName' }
    let(:ipa_file) { 'ipa_file' }
    let(:notify) { true }
    let(:distribution_list) { 'developers' }
    let(:dsym_path) { nil }
    let(:autogenerate_deploy_notes) { false }

    before do
      thrust_executor.stub(:system_or_exit)
      Thrust::UserPrompt.stub(:get_user_input)
    end


    def upload
      testflight.upload(ipa_file, notify, distribution_list, autogenerate_deploy_notes, 'staging', dsym_path)
    end

    context 'when a dSYM path is given' do
      let(:dsym_path) { "#{build_directory}/#{app_name}.app.dSYM" }

      it 'zips the dSYM' do
        expected_command = "zip -r -T -y 'build/AppName.app.dSYM.zip' 'build/AppName.app.dSYM'"
        thrust_executor.should_receive(:system_or_exit).with(expected_command)
        upload
      end

      it 'uploads the build to testflight, including the zipped dSYM' do
        expected_command = "curl http://testflightapp.com/api/builds.json -F file=@ipa_file -F dsym=@build/AppName.app.dSYM.zip -F api_token='api_token' -F team_token='team_token' -F notes=@ -F notify=True -F distribution_lists='developers'"
        thrust_executor.should_receive(:system_or_exit).with(expected_command)
        upload
      end
    end

    context 'when no dSYM path is given' do
      let(:dsym_path) { nil }

      it 'does not attempt to zip the dSYM' do
        thrust_executor.should_not_receive(:system_or_exit).with(/zip/)
        upload
      end

      it 'uploads the build to testflight' do
        expected_command = "curl http://testflightapp.com/api/builds.json -F file=@ipa_file -F api_token='api_token' -F team_token='team_token' -F notes=@ -F notify=True -F distribution_lists='developers'"
        thrust_executor.should_receive(:system_or_exit).with(expected_command)
        upload
      end
    end

    context 'when told to autogenerate deploy notes' do
      let(:autogenerate_deploy_notes) { true }

      it 'does not get the deploy notes from the user' do
        Thrust::UserPrompt.should_not_receive(:get_user_input)
        upload
      end

      it 'generates the deploy notes from commit messages and uploads them to testflight' do
        git.should_receive(:generate_notes_for_deployment).with('staging').and_return('generated_notes_file_name')
        thrust_executor.should_receive(:system_or_exit).with(/notes=@generated_notes_file_name/)
        upload
      end
    end

    context 'when not told to autogenerate deploy notes' do
      let(:autogenerate_deploy_notes) { false }

      it 'gets the deploy notes from the user and uploads them to testflight' do
        Thrust::UserPrompt.should_receive(:get_user_input).with('Deploy Notes: ', out, input).and_return('message_file_name')
        thrust_executor.should_receive(:system_or_exit).with(/notes=@message_file_name/)
        upload
      end
    end

    it 'respects the environment variable around notifications' do
      ENV.stub(:[]).with('NOTIFY').and_return('FALSE')
      expected_command = "curl http://testflightapp.com/api/builds.json -F file=@ipa_file -F api_token='api_token' -F team_token='team_token' -F notes=@ -F notify=False -F distribution_lists='developers'"
      thrust_executor.should_receive(:system_or_exit).with(expected_command)

      upload
    end
  end
end
