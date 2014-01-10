require 'spec_helper'

describe Thrust::Doctor do
  let(:out) { StringIO.new }
  subject { Thrust::Doctor.new(out) }

  # context 'when thrust.yml does not exist' do
  #   it 'prints an error' do
  #     Sandbox.play do |path|
  #       subject.run
  #       out.string.should include "ERROR"
  #     end
  #   end
  # end

  context 'when Specs do not exist' do
    it 'prints an error' do
      subject.run
      out.string.should include "ERROR"
      out.string.should include "Specs"
    end
  end
end
