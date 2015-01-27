require 'spec_helper'

describe Thrust::SchemeParser do
  describe '#parse_environment_variables' do
    let(:scheme) { 'SchemeName' }
    subject { Thrust::SchemeParser.new }

    context 'when there are multiple environment variables in the scheme' do
      before do
        Dir.mkdir('xcuserdata')
        File.open("xcuserdata/#{scheme}.xcscheme", 'w+') do |f|
          f.write(<<-XML)
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="0610" version="1.3">
   <LaunchAction>
      <EnvironmentVariables>
         <EnvironmentVariable key="CEDAR_RANDOM_SEED" value="100" isEnabled="YES"></EnvironmentVariable>
         <EnvironmentVariable key="CEDAR_REPORTER_OPTS" value="nested" isEnabled="YES"></EnvironmentVariable>
         <EnvironmentVariable key="CEDAR_GUI_SPECS" value="1" isEnabled="NO"></EnvironmentVariable>
      </EnvironmentVariables>
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
</Scheme>
          XML
        end
      end

      it 'should return all of the enabled environment variables in the scheme file' do
        environment_variables = subject.parse_environment_variables(scheme)

        expect(environment_variables).to eq({'CEDAR_RANDOM_SEED' => '100',
                                             'CEDAR_REPORTER_OPTS' => 'nested'})
      end
    end

    context 'when there is one environment variable in the scheme' do
      before do
        Dir.mkdir('xcuserdata')
        File.open("xcuserdata/#{scheme}.xcscheme", 'w+') do |f|
          f.write(<<-XML)
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="0610" version="1.3">
   <LaunchAction>
      <EnvironmentVariables>
         <EnvironmentVariable key="CEDAR_RANDOM_SEED" value="100" isEnabled="YES"></EnvironmentVariable>
      </EnvironmentVariables>
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
</Scheme>
          XML
        end
      end

      it 'should return the environment variable in the scheme file' do
        environment_variables = subject.parse_environment_variables(scheme)

        expect(environment_variables).to eq({'CEDAR_RANDOM_SEED' => '100'})
      end
    end

    context 'when there are no environment variables in the scheme' do
      before do
        Dir.mkdir('xcuserdata')
        File.open("xcuserdata/#{scheme}.xcscheme", 'w+') do |f|
          f.write(<<-XML)
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="0610" version="1.3">
   <LaunchAction>
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
</Scheme>
          XML
        end
      end

      it 'should return an empty hash' do
        environment_variables = subject.parse_environment_variables(scheme)

        expect(environment_variables.size).to eq(0)
        expect(environment_variables).to be_a(Hash)
      end
    end

    context 'when the xcodeproj_path is passed in' do
      let(:xcodeproj_path) { 'workingDirectory/../../xcodeprojPath' }

      before do
        Dir.mkdir('workingDirectory')

        # this file is in the wrong place
        Dir.mkdir('workingDirectory/xcuserdata')
        File.open("workingDirectory/xcuserdata/#{scheme}.xcscheme", 'w+') do |f|
          f.write(<<-XML)
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="0610" version="1.3">
   <LaunchAction>
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
</Scheme>
          XML
        end

        # this file should be parsed
        Dir.mkdir("#{xcodeproj_path}")
        Dir.mkdir("#{xcodeproj_path}/xcuserdata")
        File.open("#{xcodeproj_path}/xcuserdata/#{scheme}.xcscheme", 'w+') do |f|
          f.write(<<-XML)
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="0610" version="1.3">
   <LaunchAction>
      <EnvironmentVariables>
         <EnvironmentVariable key="CEDAR_RANDOM_SEED" value="100" isEnabled="YES"></EnvironmentVariable>
      </EnvironmentVariables>
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
</Scheme>
          XML
        end
      end

      it 'should search in the xcodeproj_path for the scheme' do
        environment_variables = subject.parse_environment_variables(scheme, xcodeproj_path)

        expect(environment_variables).to eq({'CEDAR_RANDOM_SEED' => '100'})
      end
    end
  end
end
