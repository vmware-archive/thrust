require 'spec_helper'

describe Thrust::XcodeTools do
  let(:thrust_executor) { Thrust::FakeExecutor.new }
  let(:out) { StringIO.new }
  let(:build_configuration) { 'Release' }
  let(:project_name) { 'AwesomeProject' }
  let(:scheme) { 'AppScheme' }
  let(:git) { double(Thrust::Git, checkout_file: 'checkout_file') }
  let(:build_directory) do
    FileUtils.mkdir_p('build').first.tap do |build_dir|
      FileUtils.mkdir_p(File.join(build_dir, "Release-iphoneos"))
    end
  end

  before do
    allow(Thrust::Git).to receive(:new).and_return(git)
    allow(FileUtils).to receive(:cmp).and_return(true)
  end

  describe '.initialize' do
    it 'requires either a project_name or workspace_name' do
      expect { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory) }.to raise_error
    end

    it 'does not allow both a project_name and workspace_name' do
      expect { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory, workspace_name: 'workspace', project_name: 'project') }.to raise_error
    end
  end

  describe '#clean_build' do
    subject { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory, project_name: project_name) }

    it 'deletes the build folder' do
      subject.clean_build
      expect(File.directory?('build')).to be_falsey
    end
  end

  describe '#test' do
    subject { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory, project_name: project_name) }

    it 'delegates to thrust executor' do
      command_result = double()

      allow(thrust_executor).to receive(:check_command_for_failure).and_return(command_result)

      expect(subject.test('scheme', 'build_configuration', 'os_version', 'device_name', '33', 'build_dir')).to eq(command_result)
      expect(thrust_executor).to have_received(:check_command_for_failure).with("xcodebuild test -scheme 'scheme' -configuration 'build_configuration' -destination 'OS=os_version,name=device_name' -destination-timeout '33' SYMROOT='build_dir'")
    end

    it 'defaults destination-timeout to 30' do
      allow(thrust_executor).to receive(:check_command_for_failure)

      subject.test('scheme', 'build_configuration', 'os_version', 'device_name', nil, 'build_dir')
      expect(thrust_executor).to have_received(:check_command_for_failure).with(/-destination-timeout '30'/)
    end
  end

  describe '#build_scheme' do
    subject { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory, project_name: project_name) }

    context 'when the build succeeds' do
      context 'when the build_sdk is iphoneos' do
        it 'calls xcodebuild with the build command' do
          subject.build_scheme(scheme, 'iphoneos')

          expected_command = {
              cmd: 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -scheme "AppScheme" -configuration Release -sdk iphoneos SYMROOT="build" CONFIGURATION_BUILD_DIR="build/Release-iphoneos" 2>&1 | grep -v \'backing file\'',
              output_file: 'build/Release-build.output'
          }
          expect(thrust_executor.system_or_exit_history.last).to eq(expected_command)
        end
      end

      context 'when the build_sdk is macosx' do
        it 'does not include CONFIGURATION_BUILD_DIR' do
          subject.build_scheme(scheme, 'macosx')

          expected_command = {
              cmd: 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -scheme "AppScheme" -configuration Release -sdk macosx SYMROOT="build" 2>&1 | grep -v \'backing file\'',
              output_file: 'build/Release-build.output'
          }
          expect(thrust_executor.system_or_exit_history.last).to eq(expected_command)
        end
      end

      context 'when the build_sdk is macosx-ish' do
        it 'does not include CONFIGURATION_BUILD_DIR' do
          subject.build_scheme(scheme, 'macosx10.10')

          expected_command = {
              cmd: 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -scheme "AppScheme" -configuration Release -sdk macosx10.10 SYMROOT="build" 2>&1 | grep -v \'backing file\'',
              output_file: 'build/Release-build.output'
          }
          expect(thrust_executor.system_or_exit_history.last).to eq(expected_command)
        end
      end

      context 'when the build is configured to clean' do
        it 'cleans in the build command' do
          subject.build_scheme(scheme, 'iphoneos', true)

          expected_command = {
              cmd: 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -scheme "AppScheme" -configuration Release -sdk iphoneos clean build SYMROOT="build" CONFIGURATION_BUILD_DIR="build/Release-iphoneos" 2>&1 | grep -v \'backing file\'',
              output_file: 'build/Release-build.output'
          }
          expect(thrust_executor.system_or_exit_history.last).to eq(expected_command)
        end
      end
    end

    context 'when the build fails' do
      before do
        thrust_executor.on_next_system_or_exit do |cmd, output_file|
          File.open(output_file, 'w') { |f| f.write('build facepalm') }
          raise(Thrust::Executor::CommandFailed, 'build no worky')
        end
      end

      it 'prints the build log' do
        expect {
          subject.build_scheme(scheme, 'iphoneos')
        }.to raise_error Thrust::Executor::CommandFailed
        expect(out.string).to include('build facepalm')
      end
    end
  end

  describe '#build_target' do
    subject { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory, project_name: project_name) }

    it 'calls xcodebuild with the build command with the target' do
      subject.build_target('TargetName', 'iphoneos')

      expected_command = {
          cmd: 'set -o pipefail && xcodebuild -project AwesomeProject.xcodeproj -target "TargetName" -configuration Release -sdk iphoneos SYMROOT="build" CONFIGURATION_BUILD_DIR="build/Release-iphoneos" 2>&1 | grep -v \'backing file\'',
          output_file: 'build/Release-build.output'
      }
      expect(thrust_executor.system_or_exit_history.last).to eq(expected_command)
    end
  end

  describe '#cleanly_create_ipa' do
    let(:target) { 'AppTarget' }
    let(:app_name) { 'AppName' }
    let(:signing_identity) { 'iPhone Distribution' }
    let(:provision_search_query) { 'query' }
    let(:provisioning_path) { 'provisioning-path' }
    subject { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory, project_name: project_name) }

    before do
      provision_search_path = File.expand_path('~/Library/MobileDevice/Provisioning Profiles')
      command = "find '#{provision_search_path}' -print0 | xargs -0 grep -lr 'query' --null | xargs -0 ls -t"
      thrust_executor.register_output_for_cmd(provisioning_path, command)
    end

    def create_ipa
      subject.cleanly_create_ipa(target, app_name, signing_identity, provision_search_query)
    end

    it 'kills the simulator' do
      create_ipa

      expect(thrust_executor.system_history).to eq([
                                                       {cmd: 'killall -m -KILL "gdb"', output_file: nil},
                                                       {cmd: 'killall -m -KILL "otest"', output_file: nil},
                                                       {cmd: 'killall -m -KILL "iOS Simulator"', output_file: nil}
                                                   ])
    end

    it 'cleans and builds the app target' do
      expect(subject).to receive(:build_target).with(target, 'iphoneos', true)
      create_ipa
    end

    it 'creates the ipa and then resigns it' do
      create_ipa

      expect(thrust_executor.system_or_exit_history[1]).to eq({cmd: "xcrun -sdk iphoneos -v PackageApplication 'build/Release-iphoneos/AppName.app' -o 'build/Release-iphoneos/AppName.ipa' --embed 'provisioning-path'", output_file: nil})
      expect(thrust_executor.system_or_exit_history[2]).to eq({cmd: "cd 'build/Release-iphoneos' && unzip 'AppName.ipa'", output_file: nil})
      expect(thrust_executor.system_or_exit_history[3]).to eq({cmd: "/usr/bin/codesign --verify --force --preserve-metadata=identifier,entitlements --sign 'iPhone Distribution' 'build/Release-iphoneos/Payload/AppName.app'", output_file: nil})
      expect(thrust_executor.system_or_exit_history[4]).to eq({cmd: "cd 'build/Release-iphoneos' && zip -qr 'AppName.ipa' 'Payload'", output_file: nil})
    end

    it 'returns the name of the ipa' do
      ipa_name = create_ipa

      expect(ipa_name).to eq('build/Release-iphoneos/AppName.ipa')
    end

    context 'when it can not find the provisioning profile' do
      let(:provisioning_path) { '' }

      it 'raises an error' do
        expect {
          create_ipa
        }.to raise_error(Thrust::XcodeTools::ProvisioningProfileNotFound)
      end
    end

    context 'when xcrun embeds the wrong provisioning profile' do
      it 'raises an error' do
        allow(FileUtils).to receive(:cmp).and_return(false)

        expect do
          create_ipa
        end.to raise_error(Thrust::XcodeTools::ProvisioningProfileNotEmbedded)
      end
    end
  end

  describe '#find_executable_name' do
    subject { Thrust::XcodeTools.new(thrust_executor, out, build_configuration, build_directory, project_name: project_name) }

    before do
      thrust_executor.register_output_for_cmd("EXECUTABLE_NAME = AwesomeExecutable\nOTHER_BUILD_SETTING = Hello", 'xcodebuild -scheme "AwesomeScheme" -showBuildSettings')
    end

    it 'returns the executable name for the provided scheme' do
      expect(subject.find_executable_name('AwesomeScheme')).to eq('AwesomeExecutable')
    end
  end
end
