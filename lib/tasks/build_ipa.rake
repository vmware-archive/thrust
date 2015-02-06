require_relative '../thrust'

@app_config = Thrust::ConfigLoader.load_configuration(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

namespace :build_ipa do
  @app_config.deployment_targets.each do |task_name, deployment_config|
    desc "Build an .ipa file for deployment to #{task_name}"
    task task_name do |_, _|
      Thrust::DeployProvider.new.instance(@app_config, deployment_config, task_name).run
    end
  end
end
