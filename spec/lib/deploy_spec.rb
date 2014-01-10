require 'spec_helper'

describe Thrust::Deploy do
  let(:app_config) do
    {
        'app_name' => 'AppName',
        'identity' => 'signing_identity',
        'project_name' => 'project_name',
        'api_token' => 'api_token'
    }
  end
  let(:thrust_config) { double(ThrustConfig, app_config: app_config, build_dir: 'build_dir') }
  let(:distribution_config) { {'notify' => 'true', 'default_list' => 'devs', 'configuration' => 'configuration', 'token' => 'team_token'} }
  let(:provisioning_search_query) { 'Provisioning Profile query' }

  describe ".make" do
    subject(:make) { Thrust::Deploy.make(thrust_config, distribution_config, provisioning_search_query) }

    it 'returns a new Thrust::Deploy' do
      expect(make).to be_instance_of(Thrust::Deploy)
    end

    it 'passes provisioning search query, thrust config, and distribution_config to the Thrust::Deploy' do
      Thrust::Deploy.should_receive(:new).with($stdout, anything, anything, anything, provisioning_search_query, thrust_config, distribution_config)
      make
    end

    it 'creates a Thrust::XCodeTools' do
      fake_xcode_tools = double
      Thrust::XCodeTools.should_receive(:new).with($stdout, 'configuration', 'build_dir', 'project_name').and_return(fake_xcode_tools)
      Thrust::Deploy.should_receive(:new) do |_, xcode_tools|
        expect(xcode_tools).to eq(fake_xcode_tools)
      end

      make
    end

    it 'creates a Thrust::Git' do
      fake_git = double
      Thrust::Git.should_receive(:new).with($stdout).and_return(fake_git)
      Thrust::Deploy.should_receive(:new) do |_, _, git|
        expect(git).to eq(fake_git)
      end

      make
    end

    it 'creates a Thrust::Testflight' do
      fake_test_flight = double
      Thrust::Testflight.should_receive(:new).with($stdout, $stdin, 'api_token', 'team_token').and_return(fake_test_flight)
      Thrust::Deploy.should_receive(:new) do |*args|
        expect(args[3]).to eq(fake_test_flight)
      end

      make
    end
  end

  describe "#run" do
    let(:out) { StringIO.new }
    let(:x_code_tools) { double(Thrust::XCodeTools, build_configuration_directory: 'build_configuration_directory', cleanly_create_ipa: 'ipa_path').as_null_object }
    let(:git) { double(Thrust::Git).as_null_object }
    let(:testflight) { double(Thrust::Testflight).as_null_object }
    subject(:deploy) { Thrust::Deploy.new(out, x_code_tools, git, testflight, provisioning_search_query, thrust_config, distribution_config) }

    before do
      git.stub(:current_commit).and_return('31758012490')
    end

    it 'ensures the working directory is clean' do
      git.should_receive(:ensure_clean)
      deploy.run
    end

    it 'updates the version number to the current git SHA' do
      x_code_tools.should_receive(:change_build_number).with('31758012490')
      deploy.run
    end

    it 'creates the ipa' do
      x_code_tools.should_receive(:cleanly_create_ipa).with('AppName', 'AppName', 'signing_identity', 'Provisioning Profile query')
      deploy.run
    end

    it 'uploads to TestFlight' do
      testflight.should_receive(:upload).with('build_configuration_directory', 'AppName', 'ipa_path', 'true', 'devs')
      deploy.run
    end

    it 'resets the changes after the deploy' do
      git.should_receive(:reset)
      deploy.run
    end
  end
end
