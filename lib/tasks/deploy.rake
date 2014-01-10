task :deploy do
  Thrust::Deploy.new($stdout).run
end