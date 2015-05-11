require 'spec_helper'

describe Thrust::IPABuilder do
  let(:app_config) do
    Thrust::AppConfig.new(
        'app_name' => 'AppName',
        'distribution_certificate' => 'signing_identity',
        'project_name' => 'project_name',
        'workspace_name' => 'workspace_name',
        'build_directory' => 'build_dir'
    )
  end

  let(:distribution_config) do
    Thrust::DeploymentTarget.new(
        'notify' => 'true',
        'distribution_list' => 'devs',
        'build_configuration' => 'configuration',
        'provisioning_search_query' => 'Provisioning Profile query',
        'note_generation_method' => 'autotag'
    )
  end

  let(:deployment_target) { 'production' }

  describe '#run' do
    let(:out) { StringIO.new }
    let(:xcode_tools) { double(Thrust::XcodeTools, build_configuration_directory: 'build_configuration_directory', cleanly_create_ipa_with_target: 'ipa_path').as_null_object }
    let(:agv_tool) { double(Thrust::AgvTool).as_null_object }
    let(:git) { double(Thrust::Git).as_null_object }
    subject(:deploy) { Thrust::IPABuilder.new(out, xcode_tools, agv_tool, git, app_config, distribution_config, deployment_target) }

    before do
      allow(git).to receive(:current_commit).and_return('31758012490')
      allow(git).to receive(:commit_count).and_return(149)
      allow(File).to receive(:exist?).with('build_configuration_directory/AppName.app.dSYM').and_return(true)
    end

    it 'ensures the working directory is clean' do
      expect(git).to receive(:ensure_clean)
      deploy.run
    end

    describe 'when the working directory is not clean' do
      it 'raises an error' do
        allow(git).to receive(:ensure_clean).and_raise(Thrust::Executor::CommandFailed)
        expect(git).to_not receive(:reset)
        expect { deploy.run }.to raise_error(Thrust::Executor::CommandFailed)
      end
    end

    describe 'when something fails' do
      before do
        allow(xcode_tools).to receive(:cleanly_create_ipa_with_target).and_raise(StandardError.new("Build Error"))
      end

      it 'should display an error message' do
        begin
          deploy.run
        rescue SystemExit
        end
        expect(out.string).to include 'Build Error'
      end

      it 'should reset the working directory' do
        expect(git).to receive(:reset).once
        begin
          deploy.run
        rescue SystemExit
        end
      end

      it 'should exit with code 1' do
        expect { deploy.run }.to raise_error SystemExit
      end
    end

    it 'resets the changes after the deploy' do
      expect(git).to receive(:reset).once
      deploy.run
    end

    context 'when versioning method is set to commits' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'versioning_method' => 'commits'
        )
      end

      it "updates the version number to the number of commits on the current branch" do
        expect(agv_tool).to receive(:change_build_number).with(149, nil, nil)
        deploy.run
      end
    end

    context 'when versioning method is set to none' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query',
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
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'versioning_method' => 'timestamp-sha'
        )
      end

      it "updates the version number to the current git SHA and a timestamp in UTC" do
        mocked_time = Time.parse("Thu Mar 29 22:33:20 PST 2014")
        allow(Time).to receive(:now).and_return(mocked_time)
        expect(agv_tool).to receive(:change_build_number).with('31758012490', '1403300633', nil)
        deploy.run
      end
    end

    context 'when versioning method is set to anything else' do
      it 'updates the version number to the current git SHA' do
        expect(agv_tool).to receive(:change_build_number).with('31758012490', nil, nil)
        deploy.run
      end
    end

    context 'when the tag is set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag',
            'tag' => 'ci'
        )
      end

      it 'should checkout the latest commit with that tag before deploying' do
        expect(git).to receive(:checkout_tag).with('ci')
        deploy.run
      end

      it 'should checkout the previous branch when it is done' do
        expect(git).to receive(:checkout_previous_branch).once
        deploy.run
      end
    end

    context 'when the tag is not set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query',
            'note_generation_method' => 'autotag'
        )
      end

      it 'should deploy from HEAD' do
        expect(git).to_not receive(:checkout_tag)
        deploy.run
      end

      it 'should not change the current branch' do
        expect(git).to_not receive(:checkout_previous_branch)
        deploy.run
      end
    end

    context 'when the target is set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query',
            'target' => 'TargetName'
        )
      end

      it 'creates the ipa, using the target' do
        expect(xcode_tools).to receive(:cleanly_create_ipa_with_target).with('TargetName', 'AppName', 'signing_identity', 'Provisioning Profile query')
        deploy.run
      end
    end

    context 'when the target is not set' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'notify' => 'true',
            'distribution_list' => 'devs',
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query',
        )
      end

      it 'defaults to the app name as the target when building the ipa' do
        expect(xcode_tools).to receive(:cleanly_create_ipa_with_target).with('AppName', 'AppName', 'signing_identity', 'Provisioning Profile query')
        deploy.run
      end
    end

    context 'when the app_name is specified in deployment target' do
      let(:distribution_config) do
        Thrust::DeploymentTarget.new(
            'app_name' => 'target_app_name',
            'notify' => 'true',
            'distribution_list' => 'devs',
            'build_configuration' => 'configuration',
            'provisioning_search_query' => 'Provisioning Profile query'
        )
      end

      it 'creates the ipa, using the app_name from the deployment target' do
        expect(xcode_tools).to receive(:cleanly_create_ipa_with_target).with('target_app_name', 'target_app_name', 'signing_identity', 'Provisioning Profile query')
        deploy.run
      end
    end
  end
end
