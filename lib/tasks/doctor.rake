require_relative '../thrust/doctor'

namespace :thrust do
  desc "Check project configuration for thrust"
  task :doctor do
    Thrust::Doctor.new($stdout).run
  end
end