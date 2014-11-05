require 'spec_helper'

describe Thrust::Tasks::IOSSpecs do
  let(:out) { double(:out) }
  let(:xcode_tools_provider) { double(Thrust::IOS::XCodeToolsProvider) }
  let(:cedar) { double(Thrust::IOS::Cedar) }

  subject { Thrust::Tasks::IOSSpecs.new(out, xcode_tools_provider, cedar) }

  describe '#run' do
    context 'when the target type is app' do
      it 'runs the specs' do
        app_config = Thrust::AppConfig.new(
          'project_name' => 'project-name',
          'workspace_name' => 'workspace-name',
          'ios_sim_path' => '/path/to/ios-sim'
        )

        thrust = double(Thrust::Config)
        thrust.stub(:build_dir).and_return('build-dir')
        thrust.stub(:app_config).and_return(app_config)

        tools_options = {
          project_name: 'project-name',
          workspace_name: 'workspace-name'
        }

        target_info = Thrust::IOSSpecTarget.new(
          'type' => 'app',
          'device' => 'device',
          'device_name' => 'device-name',
          'os_version' => 'os-version',
          'target' => 'some-target',
          'scheme' => 'some-scheme',
          'timeout' => '45',
          'build_sdk' => 'build-sdk',
          'build_configuration' => 'build-configuration'
        )

        args = {}

        xcode_tools = double(Thrust::IOS::XCodeTools)

        xcode_tools_provider.stub(:instance).with(out, 'build-configuration', 'build-dir', tools_options).and_return(xcode_tools)

        expect(xcode_tools).to receive(:build_scheme_or_target).with('some-scheme', 'build-sdk')
        expect(xcode_tools).to receive(:kill_simulator)
        expect(cedar).to receive(:run).with('build-configuration', 'some-target', 'build-sdk', 'os-version','device-name', '45', 'build-dir', '/path/to/ios-sim').and_return(:success)

        result = subject.run(thrust, target_info, args)
        expect(result).to eq(:success)
      end
    end

    context 'when the target type is bundle' do
      it 'runs the specs' do
        app_config = Thrust::AppConfig.new(
          'project_name' => 'project-name',
          'workspace_name' => 'workspace-name',
          'ios_sim_path' => 'ios-sim'
        )

        thrust = double(Thrust::Config)
        thrust.stub(:build_dir).and_return('build-dir')
        thrust.stub(:app_config).and_return(app_config)

        tools_options = {
          project_name: 'project-name',
          workspace_name: 'workspace-name'
        }

        target_info = Thrust::IOSSpecTarget.new(
          'type' => 'bundle',
          'device' => 'device',
          'device_name' => 'device-name',
          'os_version' => 'os-version',
          'timeout' => '19',
          'target' => 'some-target',
          'scheme' => 'some-scheme',
          'build_sdk' => 'build-sdk',
          'build_configuration' => 'build-configuration'
        )

        args = {}

        xcode_tools = double(Thrust::IOS::XCodeTools)

        xcode_tools_provider.stub(:instance).with(out, 'build-configuration', 'build-dir', tools_options).and_return(xcode_tools)

        expect(xcode_tools).to receive(:build_scheme_or_target).with('some-scheme', 'build-sdk')
        expect(xcode_tools).to receive(:test).with('some-target', 'build-configuration', 'os-version', 'device-name', '19', 'build-dir').and_return(:success)

        result = subject.run(thrust, target_info, args)
        expect(result).to eq(:success)
      end
    end
  end
end
