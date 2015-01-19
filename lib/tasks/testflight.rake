require_relative '../thrust'

@app_config = Thrust::ConfigLoader.load_configuration(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

namespace :testflight do
  @app_config.deployment_targets.each do |task_name, deployment_config|
    desc "Deploy iOS build to #{task_name} (use NOTIFY=false to prevent team notification)"
    task task_name do |_, _|
      Thrust::IOS::DeployProvider.new.instance(@app_config, deployment_config, task_name).run
    end
  end
end
