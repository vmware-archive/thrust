require 'spec_helper'

describe Thrust::Tasks::FocusedSpecs do
  describe '#run' do
    let(:thrust_executor) { Thrust::FakeExecutor.new }
    subject { Thrust::Tasks::FocusedSpecs.new(thrust_executor) }

    it 'returns the files that contain focused specs, ignoring frameworks' do
      app_config = Thrust::AppConfig.new({'spec_directories' => [ 'SpecDirA', 'SpecDirB' ], 'project_root' => '/pr'})
      subject.run(app_config)

      expected_command = %Q[grep -l -r -e "\\(fit(@\\|fcontext(@\\|fdescribe(@\\)" "/pr/SpecDirA" "/pr/SpecDirB" | grep -v 'Frameworks']
      expect(thrust_executor.system_history.last[:cmd]).to eq expected_command
    end
  end
end
