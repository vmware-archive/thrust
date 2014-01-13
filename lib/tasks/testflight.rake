require 'yaml'
require 'tempfile'
require File.expand_path('../../thrust', __FILE__)


@thrust = Thrust::Config.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

desc "show the current build" # TODO: delete when autotagger is added
task :current_version do
  Thrust::Executor.system_or_exit("agvtool what-version -terse")
end

namespace :testflight do
  @thrust.app_config['deployment_targets'].each do |task_name, deployment_config|
    desc "Deploy iOS build to #{task_name} (use NOTIFY=false to prevent team notification)"
    task task_name, :provision_search_query do |task, args|
      Thrust::IOS::Deploy.make(@thrust, deployment_config, args[:provision_search_query]).run
    end

    desc "Deploy Android build to #{task_name} (use NOTIFY=false to prevent team notification)"
    task "#{task_name}:android" do |task, args|
      Thrust::Android::Deploy.make(@thrust, deployment_config).run
    end
  end
end
