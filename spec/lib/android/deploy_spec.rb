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
  let(:distribution_config) { {'notify' => 'true', 'distribution_list' => 'devs', 'note_generation_method' => 'autotag' } }
  let(:deployment_target) { 'production' }

  describe ".make" do
    before do
      Thrust::Testflight.stub(:new)
    end

    subject(:make) { Thrust::Android::Deploy.make(thrust_config, distribution_config, deployment_target) }

    it 'returns a new Thrust::Android::Deploy' do
      expect(make).to be_instance_of(Thrust::Android::Deploy)
    end

    it 'passes app_config, and distribution_config to the Thrust::Android::Deploy' do
      Thrust::Android::Deploy.should_receive(:new).with($stdout, anything, anything, anything, 'true', 'devs', true, deployment_target)
      make
    end

    it 'creates a Thrust::AndroidTools' do
      fake_android_tools = double
      Thrust::Android::Tools.should_receive(:new).with($stdout).and_return(fake_android_tools)
      Thrust::Android::Deploy.should_receive(:new) do |_, tools|
        expect(tools).to eq(fake_android_tools)
      end

      make
    end

    it 'creates a Thrust::Git' do
      fake_git = double
      Thrust::Git.should_receive(:new).with($stdout).and_return(fake_git)
      Thrust::Android::Deploy.should_receive(:new) do |_, _, git|
        expect(git).to eq(fake_git)
      end

      make
    end

    it 'creates a Thrust::Testflight' do
      fake_test_flight = double
      Thrust::Testflight.should_receive(:new).with($stdout, $stdin, 'api_token', 'team_token').and_return(fake_test_flight)
      Thrust::Android::Deploy.should_receive(:new) do |*args|
        expect(args[3]).to eq(fake_test_flight)
      end

      make
    end
  end

  describe "#run" do
    let(:out) { StringIO.new }
    let(:android_tools) { double(Thrust::Android::Tools, build_signed_release: 'apk_path').as_null_object }
    let(:git) { double(Thrust::Git).as_null_object }
    let(:testflight) { double(Thrust::Testflight).as_null_object }
    subject(:deploy) { Thrust::Android::Deploy.new(out, android_tools, git, testflight, 'true', 'devs', false, deployment_target) }

    before do
      git.stub(:current_commit).and_return('31758012490')
    end

    it 'ensures the working directory is clean' do
      git.should_receive(:ensure_clean)
      deploy.run
    end

    it 'updates the version number to the current git SHA' do
      Timecop.freeze(Time.at(1389303568)) do
        android_tools.should_receive(:change_build_number).with('1401091339', '31758012490')
        deploy.run
      end
    end

    it 'creates the apk' do
      android_tools.should_receive(:build_signed_release)
      deploy.run
    end

    it 'uploads to TestFlight' do
      testflight.should_receive(:upload).with('apk_path', 'true', 'devs', false, deployment_target)
      deploy.run
    end

    it 'resets the changes after the deploy' do
      git.should_receive(:reset)
      deploy.run
    end
  end
end
