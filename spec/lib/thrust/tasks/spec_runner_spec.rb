require 'spec_helper'

describe Thrust::Tasks::SpecRunner do
  let(:out) { double(:out) }
  let(:xcode_tools_provider) { double(Thrust::XcodeToolsProvider) }
  let(:ios_spec_launcher) { double(Thrust::IOSSpecLauncher) }
  let(:osx_spec_launcher) { double(Thrust::OSXSpecLauncher) }
  let(:scheme_parser) { double(Thrust::SchemeParser) }
  let(:environment_variables) { {'environment_variable' => '5'} }

  subject { Thrust::Tasks::SpecRunner.new(out, xcode_tools_provider, ios_spec_launcher, osx_spec_launcher, scheme_parser) }

  before do
    allow(ios_spec_launcher).to receive(:run)
    allow(osx_spec_launcher).to receive(:run)
    allow(scheme_parser).to receive(:parse_environment_variables).and_return(environment_variables)
  end

  describe '#run' do
    let(:xcode_tools) { double(Thrust::XcodeTools) }
    let(:target_info) { Thrust::SpecTarget.new(
      'type' => 'app',
      'device' => 'device',
      'device_name' => 'device-name',
      'os_version' => 'os-version',
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
      allow(xcode_tools_provider).to receive(:instance).and_return(xcode_tools)
      allow(xcode_tools).to receive(:build_scheme)
      allow(xcode_tools).to receive(:kill_simulator)
      allow(xcode_tools).to receive(:find_executable_name).with('some-scheme').and_return('ExecutableName')
    end

    it 'instantiates the xcode tools correctly' do
      subject.run(app_config, target_info, {})

      expect(xcode_tools_provider).to have_received(:instance).with(
        out,
        'build-configuration',
        'build-dir',
        {project_name: 'project-name', workspace_name: 'workspace-name'}
      )
    end

    it 'builds the provided scheme' do
      subject.run(app_config, target_info, {})

      expect(xcode_tools).to have_received(:build_scheme).with('some-scheme', 'build-sdk')
    end

    it 'launches the specs using the ios spec launcher' do
      subject.run(app_config, target_info, {})

      expect(ios_spec_launcher).to have_received(:run).with('ExecutableName', 'build-configuration', 'build-sdk', 'os-version', 'device-name', '45', 'build-dir', '/path/to/ios-sim', environment_variables)
    end

    context 'when the specs are for a mac spec target' do
      it 'launches the specs using the osx spec launcher' do
        allow(target_info).to receive(:build_sdk).and_return('macosx10.9')

        subject.run(app_config, target_info, {})

        expect(osx_spec_launcher).to have_received(:run).with('ExecutableName', 'build-configuration', 'build-dir')
      end
    end

    context 'when the target type is app' do
      it 'kills the xcode tools simulator and runs the cedar suite, not replacing the dash in the device name' do
        subject.run(app_config, target_info, {})

        expect(xcode_tools).to have_received(:kill_simulator)
        expect(ios_spec_launcher).to have_received(:run).with('ExecutableName', 'build-configuration', 'build-sdk', 'os-version', 'device-name', '45', 'build-dir', '/path/to/ios-sim', environment_variables)
      end

      it 'returns the spec_launcher return value' do
        allow(ios_spec_launcher).to receive(:run).and_return(:success)

        expect(subject.run(app_config, target_info, {})).to eq(:success)
      end

      it 'should replace the space with a dash when the device name has a space' do
        allow(target_info).to receive(:device_name).and_return('device name')
        subject.run(app_config, target_info, {})

        expect(ios_spec_launcher).to have_received(:run).with('ExecutableName', 'build-configuration', 'build-sdk', 'os-version', 'device-name', '45', 'build-dir', '/path/to/ios-sim', environment_variables)
      end

      context 'when there are args' do
        it 'passes the os version and device name from the arguments to the spec launcher' do
          subject.run(app_config, target_info, {os_version: 'args-os-version', device_name: 'args-device-name'})

          expect(ios_spec_launcher).to have_received(:run).with(anything, anything, anything, 'args-os-version', 'args-device-name', anything, anything, anything, anything)
        end
      end
    end

    context 'when the target type is bundle' do
      before :each do
        allow(xcode_tools).to receive(:test)
        allow(target_info).to receive(:type).and_return('bundle')
      end

      it 'should not replace the space with a dash when the device name has a space' do
        allow(target_info).to receive(:device_name).and_return('device name')
        subject.run(app_config, target_info, {})

        expect(xcode_tools).to have_received(:test).with('some-scheme', 'build-configuration', 'os-version', 'device name', '45', 'build-dir')
      end

      it 'should replace the dash with a space when the device name has a dash' do
        allow(target_info).to receive(:device_name).and_return('device-name')
        subject.run(app_config, target_info, {})

        expect(xcode_tools).to have_received(:test).with('some-scheme', 'build-configuration', 'os-version', 'device name', '45', 'build-dir')
      end
    end
  end
end
