require 'spec_helper'

describe Thrust::ConfigLoader do
  describe '.load_configuration' do
    let(:out) { StringIO.new }
    subject { Thrust::ConfigLoader.load_configuration('/useless_dir/../relative_project_root', 'config.yml', out) }

    context 'when the thrust configuration is valid' do
      before do
        File.open 'config.yml', 'w+' do |f|
          f.write(YAML.dump({'thrust_version' => 0.6}))
        end
      end

      it 'returns a configured AppConfig for the given configured file' do
        app_config = subject
        expect(app_config).to be_instance_of(Thrust::AppConfig)

        expect(app_config.thrust_version).to eq('0.6')
        expect(app_config.project_root).to eq('/relative_project_root')
        expect(app_config.build_directory).to eq('/relative_project_root/build')
      end
    end

    context 'when the configuration version does not match the Thrust version' do
      before do
        File.open 'config.yml', 'w+' do |f|
          f.write(YAML.dump({'thrust_version' => 'version-a'}))
        end
      end

      it 'raises an exception' do
        expect { subject }.to raise_exception(Thrust::ConfigLoader::InvalidVersionConfigError)
        expect(out.string).to match /Invalid configuration/
      end
    end

    context 'when the configuration YAML is malformed' do
      before do
        File.open 'config.yml', 'w+' do |f|
          f.write('{ [ this is totally not valid yaml.')
        end
      end

      it 'exits with an error code' do
        expect { subject }.to raise_exception(Thrust::ConfigLoader::MalformedConfigError)
        expect(out.string).to match /Malformed thrust.yml/
      end
    end

    context 'when the configuration YAML is missing' do
      before do
        expect(File.exist?('config.yml')).to be_falsey
      end

      it 'exits with an error code' do
        expect { subject }.to raise_exception(Thrust::ConfigLoader::MissingConfigError)
        expect(out.string).to match /Missing thrust.yml/
      end
    end
  end
end
