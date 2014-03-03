require 'spec_helper'

describe Thrust::IOS::Deploy do
  let(:app_config) do
    {
        'app_name' => 'AppName',
        'ios_distribution_certificate' => 'signing_identity',
        'project_name' => 'project_name',
        'workspace_name' => 'workspace_name',
        'testflight' => {
            'team_token' => 'team_token',
            'api_token' => 'api_token'
        }
    }
  end
  let(:thrust_config) { double(Thrust::Config, app_config: app_config, build_dir: 'build_dir') }
  let(:distribution_config) do
    {
        'notify' => 'true',
        'distribution_list' => 'devs',
        'ios_build_configuration' => 'configuration',
        'ios_provisioning_search_query' => 'Provisioning Profile query',
        'note_generation_method' => 'autotag'
    }
  end
  let(:deployment_target) { 'production' }

  describe "#run" do
    let(:out) { StringIO.new }
    let(:x_code_tools) { double(Thrust::IOS::XCodeTools, build_configuration_directory: 'build_configuration_directory', cleanly_create_ipa: 'ipa_path').as_null_object }
    let(:agv_tool) { double(Thrust::IOS::AgvTool).as_null_object }
    let(:git) { double(Thrust::Git).as_null_object }
    let(:testflight) { double(Thrust::Testflight).as_null_object }
    subject(:deploy) { Thrust::IOS::Deploy.new(out, x_code_tools, agv_tool, git, testflight, thrust_config, distribution_config, deployment_target) }

    before do
      git.stub(:current_commit).and_return('31758012490')
      git.stub(:commit_count).and_return(149)
    end

    it 'ensures the working directory is clean' do
      git.should_receive(:ensure_clean)
      deploy.run
    end

    it 'resets the changes after the deploy' do
      git.should_receive(:reset)
      deploy.run
    end

    context "when versioning method is set to commits" do
      let(:distribution_config) do
        {
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'versioning_method' => 'commits'
        }
      end

      it "updates the version number to the number of commits on the current branch" do
        agv_tool.should_receive(:change_build_number).with(149)
        deploy.run
      end
    end

    context "when versioning method is set to anything else" do
      it 'updates the version number to the current git SHA' do
        agv_tool.should_receive(:change_build_number).with('31758012490')
        deploy.run
      end
    end

    context 'when note generation method is set to autotag' do
      let(:distribution_config) do
        {
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag'
        }
      end

      it 'uploads to TestFlight, telling it to auto-generate the deployment notes' do
        testflight.should_receive(:upload).with('ipa_path', 'true', 'devs', true, 'production', 'build_configuration_directory/AppName.app.dSYM')
        deploy.run
      end
    end

    context 'when note generation is set to anything else' do
      let(:distribution_config) do
        {
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'ask'
        }
      end

      it 'uploads to TestFlight, telling it not to auto-generate deployment notes' do
        testflight.should_receive(:upload).with('ipa_path', 'true', 'devs', false, 'production', 'build_configuration_directory/AppName.app.dSYM')
        deploy.run
      end
    end

    context 'when the target is set' do
      let(:distribution_config) do
        {
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'ios_target' => 'TargetName'
        }
      end

      it 'creates the ipa, using the target' do
        x_code_tools.should_receive(:cleanly_create_ipa).with('TargetName', 'AppName', 'signing_identity', 'Provisioning Profile query')
        deploy.run
      end
    end

    context 'when the target is not set' do
      let(:distribution_config) do
        {
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
        }
      end

      it 'defaults to the app name as the target when building the ipa' do
        x_code_tools.should_receive(:cleanly_create_ipa).with('AppName', 'AppName', 'signing_identity', 'Provisioning Profile query')
        deploy.run
      end
    end
  end
end
