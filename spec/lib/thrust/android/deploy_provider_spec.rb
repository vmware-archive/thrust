require 'spec_helper'

describe Thrust::Android::DeployProvider do
  describe "#instance" do
    let(:app_config) do
      Thrust::AppConfig.new(
        'app_name' => 'AppName',
        'project_name' => 'project_name',
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
        'note_generation_method' => 'autotag'
      )
    end

    let(:deployment_target) { 'production' }

    let(:git) { double(Thrust::Git) }
    let(:testflight) { double(Thrust::Testflight) }
    let(:tools) { double(Thrust::Android::Tools) }
    let(:executor) { double(Thrust::Executor) }

    subject(:provider) { Thrust::Android::DeployProvider.new }

    before do
      Thrust::Git.stub(:new).and_return(git)
      Thrust::Executor.stub(:new).and_return(executor)
      Thrust::Testflight.stub(:new).and_return(testflight)
      Thrust::Android::Tools.stub(:new).and_return(tools)
    end

    it 'builds the dependencies and passes thrust config, distribution_config and deployment_target to the Thrust::Android::Deploy' do
      Thrust::Testflight.should_receive(:new).with(executor, $stdout, $stdin, 'api_token', 'team_token').and_return(testflight)
      Thrust::Git.should_receive(:new).with($stdout, executor).and_return(git)
      Thrust::Android::Tools.should_receive(:new).with($stdout, executor).and_return(tools)

      Thrust::Android::Deploy.should_receive(:new).with($stdout,
        tools,
        git,
        testflight,
        distribution_config,
        deployment_target).and_call_original

      expect(provider.instance(app_config, distribution_config, deployment_target)).to be_instance_of(Thrust::Android::Deploy)

    end
  end
end

