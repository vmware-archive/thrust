require_relative '../thrust'

@thrust = Thrust::Config.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

namespace :testflight do
  android_project = File.exists?('AndroidManifest.xml')

  @thrust.app_config.deployment_targets.each do |task_name, deployment_config|
    if android_project
      desc "Deploy Android build to #{task_name} (use NOTIFY=false to prevent team notification)"
      task task_name do |_, _|
        Thrust::Android::DeployProvider.new.instance(@thrust, deployment_config, task_name).run
      end
    else
      desc "Deploy iOS build to #{task_name} (use NOTIFY=false to prevent team notification)"
      task task_name do |_, _|
        Thrust::IOS::DeployProvider.new.instance(@thrust, deployment_config, task_name).run
      end
    end
  end
end
