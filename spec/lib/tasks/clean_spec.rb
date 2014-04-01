require_relative '../../../lib/thrust/tasks/clean'

describe Thrust::Tasks::Clean do
  let(:out) { double(:out) }
  let(:xcode_tools_provider) { double('Thrust::IOS::XCodeToolsProvider') }

  subject { Thrust::Tasks::Clean.new(out, xcode_tools_provider) }

  describe '#run' do
    it 'cleans the build' do
      app_config = {
        'project_name' => 'project-name',
        'workspace_name' => 'workspace-name'
      }

      thrust = double('Thrust::Config')
      thrust.stub(:build_dir).and_return('build-dir')
      thrust.stub(:app_config).and_return(app_config)

      tools_options = {
        project_name: 'project-name',
        workspace_name: 'workspace-name'
      }

      xcode_tools = double('Thrust::IOS::XCodeTools')

      xcode_tools_provider.stub(:instance).with(out, nil, 'build-dir', tools_options).and_return(xcode_tools)

      expect(xcode_tools).to receive(:clean_build)

      subject.run(thrust)
    end
  end
end
