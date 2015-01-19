require 'spec_helper'

describe Thrust::UserPrompt do
  describe '.get_user_input' do
    let(:fin) { StringIO.new }
    let(:fout) { StringIO.new }
    let(:temp) { File.new('temp', 'w') }

    before do
      allow(Tempfile).to receive(:new).and_return(temp)
    end

    it 'prints the prompt' do
      Thrust::UserPrompt.get_user_input('My Special Prompt', fout, fin)
      expect(fout.string).to include('My Special Prompt')
    end

    it 'writes user input to a temporary file and returns the path' do
      fin.write('My Special Input')
      fin.rewind

      path = Thrust::UserPrompt.get_user_input('My Special Prompt', fout, fin)

      expect(File.read(path)).to eq('My Special Input')
    end
  end
end
