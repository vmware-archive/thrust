require_relative '../thrust'

@app_config = Thrust::ConfigLoader.load_configuration(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

namespace :autotag do
  task :create, :stage do |_, args|
    Thrust::Tasks::Autotag::Create.new.run(args[:stage])
  end

  desc 'Show the commit that is currently deployed to each environment'
  task :list do
    Thrust::Tasks::Autotag::List.new.run(@app_config)
  end
end
