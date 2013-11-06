  class XCRun
    def call(build_dir, app_name, identity)
      ipa_file = "#{build_dir}/#{app_name}.ipa"

      system_or_exit(
        [
          "xcrun",
          "-sdk iphoneos",
          "-v PackageApplication",
          "'#{build_dir}/#{app_name}.app'",
          "-o '#{ipa_file}'",
          "--sign '#{identity}'"
        ].join(" ")
      )

      ipa_file
    end

    private

    def system_or_exit(cmd, stdout = nil)
      STDERR.puts "Executing #{cmd}"
      cmd += " >#{stdout}" if stdout
      system(cmd) or raise '******** Build failed ********'
    end
  end

