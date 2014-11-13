require 'spec_helper'

describe Thrust::Android::Deploy do
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
  let(:deployment_config) { Thrust::DeploymentTarget.new({'notify' => 'true', 'distribution_list' => 'devs', 'note_generation_method' => 'autotag' }) }
  let(:deployment_target) { 'production' }

  describe "#run" do
    let(:out) { StringIO.new }
    let(:android_tools) { double(Thrust::Android::Tools, build_signed_release: 'apk_path').as_null_object }
    let(:git) { double(Thrust::Git).as_null_object }
    let(:testflight) { double(Thrust::Testflight).as_null_object }
    subject(:deploy) { Thrust::Android::Deploy.new(out, android_tools, git, testflight, deployment_config, deployment_target) }

    before do
      git.stub(:current_commit).and_return('31758012490')
    end

    it 'ensures the working directory is clean' do
      git.should_receive(:ensure_clean)
      deploy.run
    end

    it 'updates the version number to the current git SHA' do
      Timecop.freeze(Time.at(1389303568)) do
        android_tools.should_receive(:change_build_number).with('1401092139', '31758012490')
        deploy.run
      end
    end

    it 'creates the apk' do
      android_tools.should_receive(:build_signed_release)
      deploy.run
    end

    it 'uploads to TestFlight' do
      testflight.should_receive(:upload).with('apk_path', 'true', 'devs', true, deployment_target)
      deploy.run
    end

    it 'resets the changes and tags the current commit after the deploy' do
      git.should_receive(:create_tag).with('production').ordered
      git.should_receive(:reset).ordered
      deploy.run
    end
  end
end
