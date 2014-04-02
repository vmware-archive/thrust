require 'spec_helper'

describe Thrust::Android::DeployProvider do
  describe "#instance" do
    let(:app_config) do
      {
        'app_name' => 'AppName',
        'project_name' => 'project_name',
        'testflight' => {
          'team_token' => 'team_token',
          'api_token' => 'api_token'
        }
      }
    end

    let(:thrust_config) { double(Thrust::Config, app_config: app_config, build_dir: 'build_dir') }
    let(:distribution_config) { {'notify' => 'true', 'distribution_list' => 'devs', 'note_generation_method' => 'autotag' } }
    let(:deployment_target) { 'production' }

    let (:git) { double(Thrust::Git) }
    let (:testflight) { double(Thrust::Testflight) }
    let (:tools) { double(Thrust::Android::Tools) }

    subject(:provider) { Thrust::Android::DeployProvider.new }

    before do
      Thrust::Git.stub(:new).and_return(git)
      Thrust::Testflight.stub(:new).and_return(testflight)
      Thrust::Android::Tools.stub(:new).and_return(tools)
    end

    it 'builds the dependencies and passes thrust config, distribution_config and deployment_target to the Thrust::Android::Deploy' do
      Thrust::Testflight.should_receive(:new).with(an_instance_of(Thrust::Executor), $stdout, $stdin, 'api_token', 'team_token').and_return(testflight)
      Thrust::Git.should_receive(:new).with($stdout, an_instance_of(Thrust::Executor)).and_return(git)
      Thrust::Android::Tools.should_receive(:new).with(an_instance_of(Thrust::Executor), $stdout).and_return(tools)

      Thrust::Android::Deploy.should_receive(:new).with($stdout,
                                                        tools,
                                                        git,
                                                        testflight,
                                                        distribution_config['notify'],
                                                        distribution_config['distribution_list'],
                                                        true,
                                                        deployment_target).and_call_original

      expect(provider.instance(thrust_config, distribution_config, deployment_target)).to be_instance_of(Thrust::Android::Deploy)

    end
  end
end

