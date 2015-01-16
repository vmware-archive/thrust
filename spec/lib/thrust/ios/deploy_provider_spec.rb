require 'spec_helper'

describe Thrust::IOS::DeployProvider do
  describe "#instance" do
    let(:app_config) do
      Thrust::AppConfig.new(
        'app_name' => 'AppName',
        'ios_distribution_certificate' => 'signing_identity',
        'project_name' => 'project_name',
        'workspace_name' => 'workspace_name',
        'testflight' => {
          'team_token' => 'team_token',
          'api_token' => 'api_token'
        },
        'build_directory' => 'build_dir'
      )
    end

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

    let(:xcode_tools_provider) { double(Thrust::IOS::XCodeToolsProvider) }
    let(:xcode_tools) { double(Thrust::IOS::XCodeTools) }
    let(:agv_tool) { double(Thrust::IOS::AgvTool) }
    let(:git) { double(Thrust::Git) }
    let(:executor) { double(Thrust::Executor) }
    let(:testflight) { double(Thrust::Testflight) }

    subject(:provider) { Thrust::IOS::DeployProvider.new }

    before do
      Thrust::IOS::XCodeTools.stub(:new).and_return(xcode_tools)
      Thrust::IOS::AgvTool.stub(:new).and_return(agv_tool)
      Thrust::Git.stub(:new).and_return(git)
      Thrust::Executor.stub(:new).and_return(executor)
      Thrust::Testflight.stub(:new).and_return(testflight)
    end

    it 'builds the dependencies and passes provisioning search query, thrust config, and distribution_config to the Thrust::IOS::Deploy' do
      Thrust::IOS::XCodeToolsProvider.should_receive(:new).and_return(xcode_tools_provider)
      xcode_tools_provider.should_receive(:instance).with($stdout, 'configuration', 'build_dir', {project_name: 'project_name', workspace_name: 'workspace_name'}).and_return(xcode_tools)
      Thrust::Git.should_receive(:new).with($stdout, executor).and_return(git)
      Thrust::IOS::AgvTool.should_receive(:new).with(executor, git).and_return(agv_tool)
      Thrust::Testflight.should_receive(:new).with(executor, $stdout, $stdin, 'api_token', 'team_token').and_return(testflight)

      Thrust::IOS::Deploy.should_receive(:new).with($stdout, xcode_tools, agv_tool, git, testflight,
        app_config, distribution_config, deployment_target).and_call_original

      expect(provider.instance(app_config, distribution_config, deployment_target)).to be_instance_of(Thrust::IOS::Deploy)
    end
  end
end
