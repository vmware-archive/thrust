class XCodeTools

  def initialize(out, build_configuration, build_directory, project_name)
    @out = out
    @build_configuration = build_configuration
    @build_directory = build_directory
    @project_name = project_name
  end

  def change_build_number(build_number)
    Thrust::Executor.system_or_exit "agvtool new-marketing-version '#{build_number}'"
  end

  def cleanly_create_ipa(sdk, target, app_name, signing_identity, provision_search_query = nil)
    clean(sdk)
    kill_simulator
    build(target)
    create_ipa(app_name, signing_identity, provision_search_query)
  end

  private

  def clean(sdk)
    @out.puts 'Cleaning...'
    run_xcode('clean', sdk)
    FileUtils.rm_rf(@build_directory)
  end

  def kill_simulator
    @out.puts('Killing simulator...')
    Thrust::Executor.system %q[killall -m -KILL "gdb"]
    Thrust::Executor.system %q[killall -m -KILL "otest"]
    Thrust::Executor.system %q[killall -m -KILL "iPhone Simulator"]
  end

  def create_ipa(app_name, signing_identity, provision_search_query)
    @out.puts 'Packaging...'
    ipa_filename = "#{build_directory_for_config}/#{app_name}.ipa"
    Thrust::Executor.system_or_exit(
        [
            "xcrun",
            "-sdk iphoneos",
            "-v PackageApplication",
            "'#{build_directory_for_config}/#{app_name}.app'",
            "-o '#{ipa_filename}'",
            "--sign '#{signing_identity}'"
        ].join(' ')
    )
    IpaReSigner.make(ipa_filename, signing_identity, provision_search_query).call
  end

  def build(target)
    @out.puts "Building..."
    run_xcode('build', 'iphoneos', target)
  end

  def build_directory_for_config
    "#{@build_directory}/#{@build_configuration}-iphoneos"
  end

  def run_xcode(build_command, sdk = nil, target = nil)
    target_flag = target ? "-target #{target}" : "-alltargets"
    sdk_flag = sdk ? "-sdk #{sdk}" : ''

    Thrust::Executor.system_or_exit(
        [
            'set -o pipefail &&',
            'xcodebuild',
            "-project #{@project_name}.xcodeproj",
            target_flag,
            "-configuration #{@build_configuration}",
            sdk_flag,
            "#{build_command}",
            "SYMROOT=#{@build_directory.inspect}",
            '2>&1',
            "| grep -v 'backing file'"
        ].join(' '),
        output_file("#{@build_configuration}-#{build_command}")
    )
  end

  def output_file(target)
    output_dir = if ENV['IS_CI_BOX']
                   ENV['CC_BUILD_ARTIFACTS']
                 else
                   File.exists?(@build_directory) ? @build_directory : FileUtils.mkdir_p(@build_directory)
                 end

    File.join(output_dir, "#{target}.output").tap { |file| @out.puts "Output: #{file}" }
  end
end