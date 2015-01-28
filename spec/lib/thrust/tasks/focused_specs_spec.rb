require 'spec_helper'

describe Thrust::Tasks::FocusedSpecs do
  describe '#run' do
    let(:thrust_executor) { Thrust::FakeExecutor.new }
    let(:out) { StringIO.new }
    let(:expected_command) { %Q[grep -l -r -e "\\(fit(@\\|fcontext(@\\|fdescribe(@\\)" "/pr/SpecDirA" "/pr/SpecDirB" | grep -v 'Frameworks' || true] }
    let(:app_config) { Thrust::AppConfig.new({'spec_directories' => ['SpecDirA', 'SpecDirB'], 'project_root' => '/pr'}) }
    subject { Thrust::Tasks::FocusedSpecs.new(out, thrust_executor) }

    before do
      thrust_executor.register_output_for_cmd("SpecDirA/ASpec.mm\nSpecDirB/BSpec.mm\n", expected_command)
    end

    it 'prints out the files that contain focused specs, ignoring frameworks' do
      subject.run(app_config)

      expect(thrust_executor.capture_output_history.last).to eq expected_command
      expect(out.string).to match /SpecDirA\/ASpec.mm/
      expect(out.string).to match /SpecDirB\/BSpec.mm/
    end

    it 'returns an array of file names that contain focused specs, ignoring frameworks' do
      file_names = subject.run(app_config)

      expect(file_names).to match_array(['SpecDirA/ASpec.mm',
                                         'SpecDirB/BSpec.mm'])
    end

    context 'when there are no files that contain focused specs' do
      it 'returns an empty array' do
        thrust_executor.register_output_for_cmd("\n", expected_command)
        file_names = subject.run(app_config)

        expect(file_names).to be_empty
      end
    end

    context 'when there are no spec directories defined in the config' do
      let(:app_config) { Thrust::AppConfig.new({'project_root' => '/pr'}) }

      it 'exits with a helpful message' do
        expect { subject.run(app_config) }.to raise_error do |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(1)
        end

        expect(out.string).to match /Unable to find focused specs without `spec_directories` defined in thrust\.yml\./
      end
    end
  end
end
