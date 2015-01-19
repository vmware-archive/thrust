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
      allow(Thrust::Git).to receive(:new).and_return(git)
      allow(Thrust::Executor).to receive(:new).and_return(executor)
      allow(Thrust::Testflight).to receive(:new).and_return(testflight)
      allow(Thrust::Android::Tools).to receive(:new).and_return(tools)
    end

    it 'builds the dependencies and passes thrust config, distribution_config and deployment_target to the Thrust::Android::Deploy' do
      expect(Thrust::Testflight).to receive(:new).with(executor, $stdout, $stdin, 'api_token', 'team_token').and_return(testflight)
      expect(Thrust::Git).to receive(:new).with($stdout, executor).and_return(git)
      expect(Thrust::Android::Tools).to receive(:new).with($stdout, executor).and_return(tools)

      expect(Thrust::Android::Deploy).to receive(:new).with($stdout,
        tools,
        git,
        testflight,
        distribution_config,
        deployment_target).and_call_original

      expect(provider.instance(app_config, distribution_config, deployment_target)).to be_instance_of(Thrust::Android::Deploy)

    end
  end
end

