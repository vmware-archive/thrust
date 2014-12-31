require 'spec_helper'

describe Thrust::IOS::Deploy do
  let(:app_config) do
    Thrust::AppConfig.new(
        'app_name' => 'AppName',
        'ios_distribution_certificate' => 'signing_identity',
        'project_name' => 'project_name',
        'workspace_name' => 'workspace_name',
        'testflight' => {
            'team_token' => 'team_token',
            'api_token' => 'api_token'
        }
    )
  end
  let(:thrust_config) { double(Thrust::Config, app_config: app_config, build_dir: 'build_dir') }
  let(:distribution_config) do
    Thrust::DeploymentTarget.new(
        'notify' => 'true',
        'distribution_list' => 'devs',
        'ios_build_configuration' => 'configuration',
        'ios_provisioning_search_query' => 'Provisioning Profile query',
        'note_generation_method' => 'autotag'
    )
  end
  let(:deployment_target) { 'production' }

  describe '#run' do
    let(:out) { StringIO.new }
    let(:x_code_tools) { double(Thrust::IOS::XCodeTools, build_configuration_directory: 'build_configuration_directory', cleanly_create_ipa: 'ipa_path').as_null_object }
    let(:agv_tool) { double(Thrust::IOS::AgvTool).as_null_object }
    let(:git) { double(Thrust::Git).as_null_object }
    let(:testflight) { double(Thrust::Testflight).as_null_object }
    subject(:deploy) { Thrust::IOS::Deploy.new(out, x_code_tools, agv_tool, git, testflight, thrust_config, distribution_config, deployment_target) }

    before do
      git.stub(:current_commit).and_return('31758012490')
      git.stub(:commit_count).and_return(149)
      File.stub(:exist?).with('build_configuration_directory/AppName.app.dSYM').and_return(true)
    end

    it 'ensures the working directory is clean' do
      git.should_receive(:ensure_clean)
      deploy.run
    end

    describe 'when the working directory is not clean' do
      it 'raises an error' do
        git.stub(:ensure_clean).and_raise(Thrust::Executor::CommandFailed)
        git.should_not_receive(:reset)
        expect { deploy.run }.to raise_error(Thrust::Executor::CommandFailed)
      end
    end

    describe 'when something fails' do
      before do
        x_code_tools.stub(:cleanly_create_ipa).and_raise(StandardError.new("Build Error"))
      end

      it 'should display an error message' do
        begin
          deploy.run
        rescue SystemExit
        end
        expect(out.string).to include 'Build Error'
      end

      it 'should reset the working directory' do
        git.should_receive(:reset)
        begin
          deploy.run
        rescue SystemExit
        end
      end

      it 'should exit with code 1' do
        expect { deploy.run }.to raise_error SystemExit
      end
    end

    it 'tags the current commit and resets the changes after the deploy' do
      git.should_receive(:create_tag).with('production').ordered
      git.should_receive(:reset).ordered
      deploy.run
    end

    context 'when the dSYM file exists' do
      it 'should pass the path to the dSYM to #upload' do
        testflight.should_receive(:upload).with('ipa_path', 'true', 'devs', true, 'production', 'build_configuration_directory/AppName.app.dSYM')
        deploy.run
      end
    end

    context 'when the dSYM file does not exist' do
      it 'should pass nil as the dSYM file path argument' do
        File.stub(:exist?).with('build_configuration_directory/AppName.app.dSYM').and_return(false)

        testflight.should_receive(:upload).with('ipa_path', 'true', 'devs', true, 'production', nil)
        deploy.run
      end
    end

    context 'when versioning method is set to commits' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'versioning_method' => 'commits'
        )
      end

      it "updates the version number to the number of commits on the current branch" do
        agv_tool.should_receive(:change_build_number).with(149, nil, nil)
        deploy.run
      end
    end

    context 'when versioning method is set to none' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'versioning_method' => 'none'
        )
      end

      it "does not update the version number" do
        expect(agv_tool).to_not receive(:change_build_number)
        deploy.run
      end
    end

    context 'when versioning method is set to timestamp-sha' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'versioning_method' => 'timestamp-sha'
        )
      end

      it "updates the version number to the current git SHA and a timestamp in UTC" do
        mocked_time = Time.parse("Thu Mar 29 22:33:20 PST 2014")
        Time.stub(:now).and_return(mocked_time)
        agv_tool.should_receive(:change_build_number).with('31758012490', '1403300633', nil)
        deploy.run
      end
    end

    context 'when versioning method is set to anything else' do
      it 'updates the version number to the current git SHA' do
        agv_tool.should_receive(:change_build_number).with('31758012490', nil, nil)
        deploy.run
      end
    end

    context 'when note generation method is set to autotag' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag'
        )
      end

      it 'uploads to TestFlight, telling it to auto-generate the deployment notes' do
        testflight.should_receive(:upload).with('ipa_path', 'true', 'devs', true, 'production', 'build_configuration_directory/AppName.app.dSYM')
        deploy.run
      end
    end

    context 'when note generation is set to anything else' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'ask'
        )
      end

      it 'uploads to TestFlight, telling it not to auto-generate deployment notes' do
        testflight.should_receive(:upload).with('ipa_path', 'true', 'devs', false, 'production', 'build_configuration_directory/AppName.app.dSYM')
        deploy.run
      end
    end

    context 'when the tag is set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'tag' => 'ci'
        )
      end

      it 'should checkout the latest commit with that tag before deploying' do
        git.should_receive(:checkout_tag).with('ci')
        deploy.run
      end
    end

    context 'when the tag is not set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag'
        )
      end

      it 'should deploy from HEAD' do
        git.should_not_receive(:checkout_tag)
        deploy.run
      end
    end

    context 'when the target is set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
            'ios_target' => 'TargetName'
        )
      end

      it 'creates the ipa, using the target' do
        x_code_tools.should_receive(:cleanly_create_ipa).with('TargetName', 'AppName', 'signing_identity', 'Provisioning Profile query')
        deploy.run
      end
    end

    context 'when the target is not set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'ios_build_configuration' => 'configuration',
            'ios_provisioning_search_query' => 'Provisioning Profile query',
        )
      end

      it 'defaults to the app name as the target when building the ipa' do
        x_code_tools.should_receive(:cleanly_create_ipa).with('AppName', 'AppName', 'signing_identity', 'Provisioning Profile query')
        deploy.run
      end
    end
  end
end
