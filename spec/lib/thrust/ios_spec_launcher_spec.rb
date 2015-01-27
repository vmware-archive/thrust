require 'spec_helper'

describe Thrust::IOSSpecLauncher do
  let(:build_configuration) { 'build_configuration' }
  let(:build_sdk) { 'os' }
  let(:executable_name) { 'AwesomeExecutable' }
  let(:device_name) { 'device-name' }
  let(:os_version) { 'os-version' }
  let(:build_dir) { 'build_dir' }
  let(:out) { StringIO.new }
  let(:ios_sim_path) { '/path/to/my/ios-sim' }
  let(:timeout) { '45' }
  let(:environment_variables) { {'CEDAR_RANDOM_SEED' => '100', 'CEDAR_REPORTER_OPTS' => 'nested'} }
  let(:thrust_executor) { double(Thrust::Executor) }

  subject { Thrust::IOSSpecLauncher.new(out, thrust_executor) }

  describe '#run' do
    def launch_specs
      subject.run(executable_name, build_configuration, build_sdk, os_version, device_name, timeout, build_dir, ios_sim_path, environment_variables)
    end

    before do
      allow(thrust_executor).to receive(:system_or_exit)

      Dir.mkdir('tmp')
      File.open('tmp/thrust_specs_output', 'w+') { |f| f.puts 'Finished in 0.0100 seconds 1 examples, 0 failures' }
    end

    it 'launches the spec executable with ios-sim and returns true when the specs succeed' do
      success = launch_specs

      expect(success).to eq(true)

      expected_command = '/path/to/my/ios-sim launch build_dir/build_configuration-os/AwesomeExecutable.app --devicetypeid "com.apple.CoreSimulator.SimDeviceType.device-name, os-version"'
      expect(thrust_executor).to have_received(:system_or_exit).with(/#{expected_command}/)
    end

    it 'passes timeout to ios-sim' do
      launch_specs

      expect(thrust_executor).to have_received(:system_or_exit).with(/--timeout 45/)
    end

    it 'sets the CFFIXED_USER_HOME to a tmp directory' do
      launch_specs

      expect(thrust_executor).to have_received(:system_or_exit).with(/--setenv CFFIXED_USER_HOME="\/tmp"/)
    end

    it 'passes the custom environment variables to ios-sim' do
      launch_specs

      expect(thrust_executor).to have_received(:system_or_exit).with(/--setenv CEDAR_RANDOM_SEED="100"/)
      expect(thrust_executor).to have_received(:system_or_exit).with(/--setenv CEDAR_REPORTER_OPTS="nested"/)
    end

    it 'cleans up the spec output' do
      launch_specs

      expect(Dir.exists?('tmp')).to be_falsey
    end

    it 'returns false when the command fails with a test failure' do
      File.open('tmp/thrust_specs_output', 'w+') { |f| f.puts 'FAILURE MyScene should fail MySceneSpec.mm:31 Expected <NO> to evaluate to true Finished in 0.0108 seconds 2 examples, 1 failures' }

      expect(launch_specs).to be_falsey
    end

    it 'returns false when the command fails with an exception' do
      File.open('tmp/thrust_specs_output', 'w+') { |f| f.puts 'EXCEPTION MyScene should blow up Finished in 0.0108 seconds 2 examples, 1 failures' }

      expect(launch_specs).to be_falsey
    end

    it "returns false when the specs don't finish" do
      File.open('tmp/thrust_specs_output', 'w+') { |f| f.puts '..' }

      expect(launch_specs).to be_falsey
    end

    context 'when no ios_sim_path is provided' do
      let(:ios_sim_path) { nil }

      it 'defaults to system-installed ios-sim' do
        launch_specs

        expect(thrust_executor).to have_received(:system_or_exit).with(/ios-sim/)
      end
    end

    context 'when no timeout is provided' do
      let(:timeout) { nil }

      it 'defaults to 30' do
        launch_specs

        expect(thrust_executor).to have_received(:system_or_exit).with(/--timeout 30/)
      end
    end
  end
end
