require_relative '../thrust'

@thrust = Thrust::Config.make(Dir.getwd, File.join(Dir.getwd, 'thrust.yml'))

namespace :autotag do
  task :create, :stage do |_, args|
    Thrust::Tasks::Autotag::Create.new.run(args[:stage])
  end

  desc 'Show the commit that is currently deployed to each environment'
  task :list do
    Thrust::Tasks::Autotag::List.new.run(@thrust)
  end
end
