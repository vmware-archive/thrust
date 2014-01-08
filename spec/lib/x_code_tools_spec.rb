require 'spec_helper'

describe XCodeTools do
  let(:out) { StringIO.new }
  let(:build_configuration) { 'Release' }
  let(:project_name) { 'AwesomeProject' }
  let(:build_directory) do
    FileUtils.mkdir_p('build').first.tap do |build_dir|
      FileUtils.touch(File.join(build_dir, "garbage_build_file"))
    end
  end
  subject(:x_code_tools) { XCodeTools.new(out, build_configuration, build_directory, project_name) }

  describe '#cleanly_create_ipa' do
    let(:sdk) { 'iphoneos' }
    let(:target) { 'AppTarget' }
    let(:app_name) { 'AppName' }
    let(:signing_identity) { 'iPhone Distribution' }
    let(:provision_search_query) { 'query' }

    before do
      Thrust::Executor.stub(:system_or_exit)
      Thrust::Executor.stub(:system)
      IpaReSigner.stub(:make) { double(:ipa_resigner).as_null_object }
    end

    def create_ipa
      x_code_tools.cleanly_create_ipa(sdk, target, app_name, signing_identity, provision_search_query)
    end

    it 'asks xcodebuild to clean' do
      expected_command = 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -alltargets -configuration Release -sdk iphoneos clean SYMROOT="build" 2>&1 | grep -v \'backing file\''
      expected_output = 'build/Release-clean.output'
      Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

      create_ipa
    end

    it 'deletes the build folder' do
      create_ipa
      expect(File.file?('build/garbage_build_file')).to be_false
    end

    it 'kills the simulator' do
      Thrust::Executor.should_receive(:system).with('killall -m -KILL "gdb"')
      Thrust::Executor.should_receive(:system).with('killall -m -KILL "otest"')
      Thrust::Executor.should_receive(:system).with('killall -m -KILL "iPhone Simulator"')

      create_ipa
    end

    it 'builds the app' do
      expected_command = 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -target AppTarget -configuration Release -sdk iphoneos build SYMROOT="build" 2>&1 | grep -v \'backing file\''
      expected_output = 'build/Release-build.output'
      Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

      create_ipa
    end

    it 'creates the ipa' do
      expected_command = "xcrun -sdk iphoneos -v PackageApplication 'build/Release-iphoneos/AppName.app' -o 'build/Release-iphoneos/AppName.ipa' --sign 'iPhone Distribution'"
      Thrust::Executor.should_receive(:system_or_exit).with(expected_command)

      create_ipa
    end

    it 'resigns the ipa' do
      ipa_resigner = double(:ipa_resigner).tap { |resigner| resigner.should_receive(:call) }
      IpaReSigner.should_receive(:make).with('build/Release-iphoneos/AppName.ipa', signing_identity, provision_search_query) { ipa_resigner }

      create_ipa
    end
  end
end
