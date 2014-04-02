require 'colorize'

class Thrust::Android::Tools
  def initialize(out = $stdout, thrust_executor = Thrust::Executor.new)
    @thrust_executor = thrust_executor
    @out = out
  end

  def change_build_number(version_code, version_name)
    @thrust_executor.system_or_exit(
        "sed -i ''" +
            " -e 's/android:versionCode=\"[0-9]*\"/android:versionCode=\"#{version_code}\"/'" +
            " -e 's/android:versionName=\"\\([^ \"]*\\)[^\"]*\"/android:versionName=\"\\1 (#{version_name})\"/'" +
            " AndroidManifest.xml")
    @thrust_executor.system_or_exit(
        "sed -i ''" +
            " '1,/<version>/s/<version>\\([^- <]*\\)[^<]*<\\/version>/<version>\\1 (#{version_name})<\\/version>/'" +
            " pom.xml")
  end

  def build_signed_release
    verify_android_installed!
    @thrust_executor.system_or_exit('mvn clean package -Prelease')
    Dir.glob('target/*-signed-aligned.apk').first or raise 'Signed APK was not generated'
  end

  private

  def verify_android_installed!
    if ENV['ANDROID_HOME'].nil?
      if File.directory?('/usr/local/opt/android-sdk')
        @out.puts 'Setting /usr/local/opt/android-sdk as ANDROID_HOME...'.magenta
        ENV['ANDROID_HOME'] = '/usr/local/opt/android-sdk'
      else
        raise('**********Android is not installed. Run `brew install android`.**********')
      end
    end
  end
end
