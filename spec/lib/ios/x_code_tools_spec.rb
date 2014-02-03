require 'spec_helper'

describe Thrust::IOS::XCodeTools do
  let(:out) { StringIO.new }
  let(:build_configuration) { 'Release' }
  let(:project_name) { 'AwesomeProject' }
  let(:os) { 'iphoneos' }
  let(:target) { 'AppTarget' }
  let(:git) { double(Thrust::Git, checkout_file: 'checkout_file') }
  let(:build_directory) do
    FileUtils.mkdir_p('build').first.tap do |build_dir|
      FileUtils.mkdir_p(File.join(build_dir, "Release-iphoneos"))
    end
  end

  before do
    Thrust::Executor.stub(:system_or_exit)
    Thrust::Executor.stub(:capture_output_from_system)
    Thrust::Executor.stub(:system)
    Thrust::Git.stub(:new).and_return(git)
  end

  describe '.initialize' do
    it 'requires either a project_name or workspace_name' do
      expect { Thrust::IOS::XCodeTools.new(out, build_configuration, build_directory) }.to raise_error
    end

    it 'does not allow both a project_name and workspace_name' do
      expect { Thrust::IOS::XCodeTools.new(out, build_configuration, build_directory, workspace_name: 'workspace', project_name: 'project') }.to raise_error
    end
  end

  describe '.build_configurations' do

  end

  context 'for an .xcodeproj based project' do
    subject(:x_code_tools) { Thrust::IOS::XCodeTools.new(out, build_configuration, build_directory, project_name: project_name) }

    describe '#clean_build' do
      it 'asks xcodebuild to clean' do
        clean_command = 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -alltargets -configuration Release clean SYMROOT="build" 2>&1 | grep -v \'backing file\''
        clean_output = 'build/Release-clean.output'
        Thrust::Executor.should_receive(:system_or_exit).with(clean_command, clean_output)
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
        build_command = 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -arch i386 -target "AppTarget" -configuration Release -sdk iphoneos build SYMROOT="build" 2>&1 | grep -v \'backing file\''
        build_output = 'build/Release-build.output'

        Thrust::Executor.should_receive(:system_or_exit).with(build_command, build_output)

        subject.clean_and_build_target(target, os)
      end
    end
  end

  context 'for an .xcworkspace based project' do
    let (:workspace_name) { 'AwesomeWorkspace' }
    subject(:x_code_tools) { Thrust::IOS::XCodeTools.new(out, build_configuration, build_directory, workspace_name: workspace_name) }

    describe '#clean_build' do
      it 'asks xcodebuild to clean' do

        expected_command = 'xcodebuild -workspace AwesomeWorkspace.xcworkspace -list'
        expected_output = <<LIST_OUTPUT
Information about workspace "AwesomeWorkspace":
    Schemes:
        AwesomeProject
        Specs (AwesomeProject)
        OtherProject
        Specs
LIST_OUTPUT

        Thrust::Executor.should_receive(:capture_output_from_system).with(expected_command).and_return(expected_output)

        expected_command = 'set -o pipefail && xcodebuild -workspace AwesomeWorkspace.xcworkspace -scheme "AwesomeProject" -configuration Release clean SYMROOT="build" 2>&1 | grep -v \'backing file\''
        expected_output = 'build/Release-clean.output'
        Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

        expected_command = 'set -o pipefail && xcodebuild -workspace AwesomeWorkspace.xcworkspace -scheme "Specs (AwesomeProject)" -configuration Release clean SYMROOT="build" 2>&1 | grep -v \'backing file\''
        expected_output = 'build/Release-clean.output'
        Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

        expected_command = 'set -o pipefail && xcodebuild -workspace AwesomeWorkspace.xcworkspace -scheme "OtherProject" -configuration Release clean SYMROOT="build" 2>&1 | grep -v \'backing file\''
        expected_output = 'build/Release-clean.output'
        Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

        expected_command = 'set -o pipefail && xcodebuild -workspace AwesomeWorkspace.xcworkspace -scheme "Specs" -configuration Release clean SYMROOT="build" 2>&1 | grep -v \'backing file\''
        expected_output = 'build/Release-clean.output'
        Thrust::Executor.should_receive(:system_or_exit).with(expected_command, expected_output)

        subject.clean_build
      end

      it 'deletes the build folder' do
        subject.clean_build
        expect(File.directory?('build/Release-iphoneos')).to be_false
      end
    end

    describe '#clean_and_build_scheme' do
      it 'cleans the build' do
        subject.should_receive(:clean_build)
        subject.clean_and_build_target(target, os)
      end

      it 'calls xcodebuild with the build command' do
        build_command = 'set -o pipefail && xcodebuild -workspace AwesomeWorkspace.xcworkspace -arch i386 -scheme "AppTarget" -configuration Release -sdk iphoneos build SYMROOT="build" 2>&1 | grep -v \'backing file\''
        build_output = 'build/Release-build.output'
        Thrust::Executor.should_receive(:system_or_exit).with(build_command, build_output)

        subject.clean_and_build_target(target, os)
      end
    end
  end

  describe '#change_build_number' do
    subject(:x_code_tools) { Thrust::IOS::XCodeTools.new(out, build_configuration, build_directory, project_name: project_name) }

    it 'updates the build number' do
      Thrust::Executor.should_receive(:system_or_exit).with("agvtool new-version -all 'abcdef'")
      x_code_tools.change_build_number('abcdef')
    end

    it 'does not change the project file (only changing Info.plist)' do
      git.should_receive(:checkout_file).with('*.xcodeproj')
      x_code_tools.change_build_number('abcdef')
    end
  end

  describe '#cleanly_create_ipa' do
    let(:app_name) { 'AppName' }
    let(:signing_identity) { 'iPhone Distribution' }
    let(:provision_search_query) { 'query' }
    let(:provisioning_path) { 'provisioning-path' }
    subject(:x_code_tools) { Thrust::IOS::XCodeTools.new(out, build_configuration, build_directory, project_name: project_name) }

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
