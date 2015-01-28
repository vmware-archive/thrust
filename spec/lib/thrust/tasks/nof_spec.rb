require 'spec_helper'

describe Thrust::Tasks::Nof do
  subject { Thrust::Tasks::Nof.new(executor, focused_spec_task) }
  let(:executor) { Thrust::FakeExecutor.new }
  let(:focused_spec_task) { double(Thrust::Tasks::FocusedSpecs)}
  let(:app_config) { Thrust::AppConfig.new({}) }

  describe '#run' do
    it 'uses the files returned from focused_specs to remove focused specs' do
      allow(focused_spec_task).to receive(:run).with(app_config).and_return(['FileA', 'FileB'])

      subject.run(app_config)

      expect(executor.system_or_exit_history.length).to eq(1)

      expected_command = %Q[sed -i '' -e 's/fit(@/it(@/g;' -e 's/fcontext(@/context(@/g;' -e 's/fdescribe(@/describe(@/g;' "FileA" "FileB"]
      expect(executor.system_or_exit_history[0][:cmd]).to eq(expected_command)
    end

    it 'returns early when there are no focused specs' do
      allow(focused_spec_task).to receive(:run).with(app_config).and_return([])

      subject.run(app_config)

      expect(executor.system_or_exit_history.length).to eq(0)
    end
  end
end
