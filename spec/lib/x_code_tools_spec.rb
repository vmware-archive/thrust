require 'spec_helper'

describe Thrust::XCodeTools do
  let(:out) { StringIO.new }
  let(:build_configuration) { 'Release' }
  let(:project_name) { 'AwesomeProject' }
  let(:os) { 'iphoneos' }
  let(:target) { 'AppTarget' }
  let(:build_directory) do
    FileUtils.mkdir_p('build').first.tap do |build_dir|
      FileUtils.mkdir_p(File.join(build_dir, "Release-iphoneos"))
    end
  end
  subject(:x_code_tools) { Thrust::XCodeTools.new(out, build_configuration, build_directory, project_name) }

  before do
    Thrust::Executor.stub(:system_or_exit)
    Thrust::Executor.stub(:system)
  end

  describe '#clean_build' do
    it 'asks xcodebuild to clean' do
      expected_command = 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -alltargets -configuration Release  clean SYMROOT="build" 2>&1 | grep -v \'backing file\''
      expected_output = 'build/Release-clean.output'
      Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

      subject.clean_build
    end

    it 'deletes the build folder' do
      subject.clean_build
      expect(File.directory?('build/Release-iphoneos')).to be_false
    end
  end

  describe '#clean_and_build_target' do
    it 'cleans the build' do
      subject.should_receive(:clean_build)
      subject.clean_and_build_target(target, os)
    end

    it 'calls xcodebuild with the build command' do
      expected_command = 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -target AppTarget -configuration Release -sdk iphoneos build SYMROOT="build" 2>&1 | grep -v \'backing file\''
      expected_output = 'build/Release-build.output'
      Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

      subject.clean_and_build_target(target, os)
    end

  end
  
  describe '#cleanly_create_ipa' do

    let(:app_name) { 'AppName' }
    let(:signing_identity) { 'iPhone Distribution' }
    let(:provision_search_query) { 'query' }
    let(:provisioning_path) { 'provisioning-path' }

    before do
      x_code_tools.stub(:`).and_return(provisioning_path)
    end

    def create_ipa
      x_code_tools.cleanly_create_ipa(target, app_name, signing_identity, provision_search_query)
    end

    it 'cleans the build' do
      subject.should_receive(:clean_build).and_call_original
      create_ipa
    end

    it 'kills the simulator' do
      Thrust::Executor.should_receive(:system).with('killall -m -KILL "gdb"')
      Thrust::Executor.should_receive(:system).with('killall -m -KILL "otest"')
      Thrust::Executor.should_receive(:system).with('killall -m -KILL "iPhone Simulator"')

      create_ipa
    end

    it 'builds the app' do
      subject.should_receive(:build_target).with(target, os)
      create_ipa
    end

    it 'creates the ipa' do
      expected_command = "xcrun -sdk iphoneos -v PackageApplication 'build/Release-iphoneos/AppName.app' -o 'build/Release-iphoneos/AppName.ipa' --sign 'iPhone Distribution' --embed '#{provisioning_path}'"
      Thrust::Executor.should_receive(:system_or_exit).with(expected_command)

      create_ipa
    end

    context 'when it can not find the provisioning profile' do
      let(:provisioning_path) { 'nonexistent-file' }

      it 'raises an error' do
        x_code_tools.cleanly_create_ipa(target, app_name, signing_identity, provisioning_path)
      end
    end
  end
end
