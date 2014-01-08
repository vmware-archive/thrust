require 'spec_helper'

describe Thrust::Deploy do
  let(:out) { StringIO.new }
  let(:x_code_tools) { double(XCodeTools).as_null_object }
  subject { Thrust::Deploy.new(out, x_code_tools) }

  context 'when git is clean' do
    before do
      # x_code_tools.stub(:change_build_number)
      Git.stub(:is_dirty?).and_return(false)
      Git.stub(:current_commit).and_return('31758012490')
    end

    it 'should update the version number to the current git SHA' do
      x_code_tools.should_receive(:change_build_number).with('31758012490')
      subject.run
    end

    it 'it should create the ipa' do
      x_code_tools.should_receive(:cleanly_create_ipa)
      subject.run
    end

    xit 'should upload to TestFlight' do
      Testflight.should_receive(:upload)
      subject.run
    end

    xit 'should reset the changes after the deploy' do
      Git.should_receive(:reset)
      subject.run
    end
  end
end