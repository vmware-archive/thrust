class Thrust::Cedar


  def self.run(build_configuration, target, sdk, os, device, build_dir, app_config)
    return_code = 1
    if os == 'macosx'
      build_path = File.join(build_dir, build_configuration)
      app_dir = File.join(build_path, target)
      return_code = grep_cmd_for_failure("DYLD_FRAMEWORK_PATH=#{build_path.inspect} #{app_dir}")
    else
      binary = app_config['sim_binary']
      sim_dir = File.join(build_dir, "#{build_configuration}-#{os}", "#{target}.app")
      if binary =~ /waxim%/
        return_code = grep_cmd_for_failure(%Q[#{binary} -s #{sdk} -f #{device} -e CFFIXED_USER_HOME=#{Dir.tmpdir} -e CEDAR_HEADLESS_SPECS=1 -e CEDAR_REPORTER_CLASS=CDRDefaultReporter #{sim_dir}])
      elsif binary =~ /ios-sim$/
        return_code = grep_cmd_for_failure(%Q[#{binary} launch #{sim_dir} --sdk #{sdk} --family #{device} --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
      else
        puts "Unknown binary for running specs: '#{binary}'"
      end
    end
    return return_code
  end

  private

  def self.grep_cmd_for_failure(cmd)
    STDERR.puts "Executing #{cmd} and checking for FAILURE"
    result = %x[#{cmd} 2>&1]
    STDERR.puts "Results:"
    STDERR.puts result

    if !result.include?("Finished") || result.include?("FAILURE") || result.include?("EXCEPTION")
      return 1
    else
      return 0
    end
  end

end