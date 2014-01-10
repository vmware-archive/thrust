class Thrust::Android::Tools
  def initialize(out)
    @out = out
    raise 'ANDROID_HOME not set' if ENV['ANDROID_HOME'].nil?
  end

  def change_build_number(version_code, version_name)
    Thrust::Executor.system_or_exit(
      "sed -i ''" +
        " -e 's/android:versionCode=\"[0-9]*\"/android:versionCode=\"#{version_code}\"/'" +
        " -e 's/android:versionName=\"\\([^ \"]*\\)[^\"]*\"/android:versionName=\"\\1 (#{version_name})\"/'" +
        " AndroidManifest.xml")
    Thrust::Executor.system_or_exit(
      "sed -i ''" +
        " '1,/<version>/s/<version>\\([^- <]*\\)[^<]*<\\/version>/<version>\\1 (#{version_name})<\\/version>/'" +
        " pom.xml")
  end

  def build_signed_release
    Thrust::Executor.system_or_exit('mvn clean package -Prelease')
    Dir.glob('target/*-signed-aligned.apk').first or raise 'Signed APK was not generated'
  end
end
