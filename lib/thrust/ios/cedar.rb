class Thrust::IOS::Cedar

  def self.run(out, build_configuration, target, runtime_sdk, build_sdk, device, build_dir, simulator_binary)
    if build_sdk == 'macosx'
      build_path = File.join(build_dir, build_configuration)
      app_dir = File.join(build_path, target)
      Thrust::Executor.check_command_for_failure("DYLD_FRAMEWORK_PATH=#{build_path.inspect} #{app_dir}")
    else
      app_executable = File.join(build_dir, "#{build_configuration}-#{build_sdk}", "#{target}.app")

      if simulator_binary =~ /waxim%/
        Thrust::Executor.check_command_for_failure(%Q[#{simulator_binary} -s #{runtime_sdk} -f #{device} -e CFFIXED_USER_HOME=#{Dir.tmpdir} -e CEDAR_HEADLESS_SPECS=1 -e CEDAR_REPORTER_CLASS=CDRDefaultReporter #{app_executable}])
      elsif simulator_binary =~ /ios-sim$/
        Thrust::Executor.check_command_for_failure(%Q[#{simulator_binary} launch #{app_executable} --sdk #{runtime_sdk} --family #{device} --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
      else
        out.puts "Unknown binary for running specs: '#{simulator_binary}'"
        false
      end
    end
  end
end
