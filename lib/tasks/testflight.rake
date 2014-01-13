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
    task task_name do |_, _|
      Thrust::IOS::Deploy.make(@thrust, deployment_config).run

      Rake::Task['autotag:create'].invoke(task_name)
    end

    desc "Deploy Android build to #{task_name} (use NOTIFY=false to prevent team notification)"
    task "#{task_name}:android" do |_, _|
      Thrust::Android::Deploy.make(@thrust, deployment_config).run

      Rake::Task['autotag:create'].invoke(task_name)
    end
  end
end

namespace :autotag do
  task :create, :stage do |_, args|
    `autotag create #{args[:stage]}`
  end

  desc 'Show the commit that is currently deployed to each environment'
  task :list do
    @thrust.app_config['deployment_targets'].each do |deployment_target, _|
      list = `autotag list #{deployment_target}`
      sha_of_latest_commit = list.split('\n').last.split(' ').first
      commit_summary = `git log --oneline -n 1 #{sha_of_latest_commit}`
      puts "#{deployment_target}:".blue + " #{commit_summary}"
    end
  end
end
