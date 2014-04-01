require_relative '../../../lib/thrust/tasks/ios_specs'

describe Thrust::Tasks::IOSSpecs do
  let(:out) { double(:out) }
  let(:xcode_tools_provider) { double('Thrust::IOS::XCodeToolsProvider') }
  let(:cedar) { double('Thrust::IOS::Cedar') }

  subject { Thrust::Tasks::IOSSpecs.new(out, xcode_tools_provider, cedar) }

  describe '#run' do
    context 'when the target type is app' do
      it 'runs the specs' do
        app_config = {
          'project_name' => 'project-name',
          'workspace_name' => 'workspace-name',
          'ios_sim_binary' => 'ios-sim'
        }

        thrust = double('Thrust::Config')
        thrust.stub(:build_dir).and_return('build-dir')
        thrust.stub(:app_config).and_return(app_config)

        tools_options = {
          project_name: 'project-name',
          workspace_name: 'workspace-name'
        }

        build_configuration = double(:build_configuration)

        target_info = {
          'type' => 'app',
          'device' => 'device',
          'target' => 'some-target',
          'scheme' => 'some-scheme',
          'build_sdk' => 'build-sdk',
          'runtime_sdk' => 'runtime-sdk',
          'build_configuration' => build_configuration
        }

        args = {}

        xcode_tools = double('Thrust::IOS::XCodeTools')

        xcode_tools_provider.stub(:instance).with(out, build_configuration, 'build-dir', tools_options).and_return(xcode_tools)

        expect(xcode_tools).to receive(:build_scheme_or_target).with('some-scheme', 'build-sdk', 'i386')
        expect(cedar).to receive(:run).with(build_configuration, 'some-target', 'runtime-sdk', 'build-sdk', 'device', 'build-dir', 'ios-sim').and_return(:success)

        result = subject.run(thrust, target_info, args)
        expect(result).to eq(:success)
      end
    end

    context 'when the target type is bundle' do
      it 'runs the specs' do
        app_config = {
          'project_name' => 'project-name',
          'workspace_name' => 'workspace-name',
          'ios_sim_binary' => 'ios-sim'
        }

        thrust = double('Thrust::Config')
        thrust.stub(:build_dir).and_return('build-dir')
        thrust.stub(:app_config).and_return(app_config)

        tools_options = {
          project_name: 'project-name',
          workspace_name: 'workspace-name'
        }

        build_configuration = double(:build_configuration)

        target_info = {
          'type' => 'bundle',
          'device' => 'device',
          'target' => 'some-target',
          'scheme' => 'some-scheme',
          'build_sdk' => 'build-sdk',
          'runtime_sdk' => 'runtime-sdk',
          'build_configuration' => build_configuration
        }

        args = {}

        xcode_tools = double('Thrust::IOS::XCodeTools')

        xcode_tools_provider.stub(:instance).with(out, build_configuration, 'build-dir', tools_options).and_return(xcode_tools)

        expect(xcode_tools).to receive(:build_scheme_or_target).with('some-scheme', 'build-sdk', 'i386')
        expect(xcode_tools).to receive(:test).with('some-target', build_configuration, 'runtime-sdk', 'build-dir').and_return(:success)

        result = subject.run(thrust, target_info, args)
        expect(result).to eq(:success)
      end
    end
  end
end
