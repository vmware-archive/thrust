require 'spec_helper'

describe Thrust::Tasks::IOSSpecs do
  let(:out) { double(:out) }
  let(:xcode_tools_provider) { double(Thrust::IOS::XCodeToolsProvider) }
  let(:cedar) { double(Thrust::IOS::Cedar) }

  subject { Thrust::Tasks::IOSSpecs.new(out, xcode_tools_provider, cedar) }

  before do
    allow(cedar).to receive(:run)
  end

  describe '#run' do
    let(:xcode_tools) { double(Thrust::IOS::XCodeTools) }
    let(:target_info) { Thrust::IOSSpecTarget.new(
      'type' => 'app',
      'device' => 'device',
      'device_name' => 'device-name',
      'os_version' => 'os-version',
      'target' => 'some-target',
      'scheme' => 'some-scheme',
      'timeout' => '45',
      'build_sdk' => 'build-sdk',
      'build_configuration' => 'build-configuration'
    ) }

    let(:app_config) {
      Thrust::AppConfig.new(
        'project_name' => 'project-name',
        'workspace_name' => 'workspace-name',
        'ios_sim_path' => '/path/to/ios-sim',
        'build_directory' => 'build-dir')
    }

    before do
      xcode_tools_provider.stub(:instance).and_return(xcode_tools)
      xcode_tools.stub(:build_scheme_or_target)
      xcode_tools.stub(:kill_simulator)
    end

    it 'instantiates, and builds the xcode tools correctly' do
      subject.run(app_config, target_info, {})

      expect(xcode_tools_provider).to have_received(:instance).with(
        out,
        'build-configuration',
        'build-dir',
        {project_name: 'project-name', workspace_name: 'workspace-name'}
      )
      expect(xcode_tools).to have_received(:build_scheme_or_target).with('some-scheme', 'build-sdk')
    end

    context 'when the device name is present' do
      it 'pass the correct arguments to cedar#run' do
        target_info.stub(device_name: 'device-name')
        subject.run(app_config, target_info, {})

        expect(cedar).to have_received(:run).with('build-configuration', 'some-target', 'build-sdk', 'os-version', 'device-name', '45', 'build-dir', '/path/to/ios-sim')
      end
    end

    context 'when the device name is missing' do
      it 'not throw a runtime exception' do
        target_info.stub(device_name: nil)

        expect { subject.run(app_config, target_info, {}) }.to_not raise_exception

        expect(cedar).to have_received(:run).with('build-configuration', 'some-target', 'build-sdk', 'os-version', nil, '45', 'build-dir', '/path/to/ios-sim')
      end
    end

    context 'when the target type is app' do
      it 'kills the xcode tools simulator and runs the cedar suite, not replacing the dash in the device name' do
        subject.run(app_config, target_info, {})

        expect(xcode_tools).to have_received(:kill_simulator)
        expect(cedar).to have_received(:run).with('build-configuration', 'some-target', 'build-sdk', 'os-version', 'device-name', '45', 'build-dir', '/path/to/ios-sim')
      end

      it 'returns the cedar return value' do
        cedar.stub(run: :success)

        expect(subject.run(app_config, target_info, {})).to eq(:success)
      end

      it 'should replace the space with a dash when the device name has a space' do
        target_info.stub(device_name: 'device name')
        subject.run(app_config, target_info, {})

        expect(cedar).to have_received(:run).with('build-configuration', 'some-target', 'build-sdk', 'os-version', 'device-name', '45', 'build-dir', '/path/to/ios-sim')
      end

      context 'when there are args' do
        it 'passes the os version and device name from the arguments to the cedar runner' do
          subject.run(app_config, target_info, {os_version: 'args-os-version', device_name: 'args-device-name'})

          expect(cedar).to have_received(:run).with(anything, anything, anything, 'args-os-version', 'args-device-name', anything, anything, anything)
        end
      end
    end

    context 'when the target type is bundle' do
      before :each do
        xcode_tools.stub(:test)
        target_info.stub(type: 'bundle')
      end

      it 'should not replace the space with a dash when the device name has a space' do
        target_info.stub(device_name: 'device name')
        subject.run(app_config, target_info, {})

        expect(xcode_tools).to have_received(:test).with('some-target', 'build-configuration', 'os-version', 'device name', '45', 'build-dir')
      end

      it 'should replace the dash with a space when the device name has a dash' do
        target_info.stub(device_name: 'device-name')
        subject.run(app_config, target_info, {})

        expect(xcode_tools).to have_received(:test).with('some-target', 'build-configuration', 'os-version', 'device name', '45', 'build-dir')
      end
    end
  end
end
