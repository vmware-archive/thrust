module Thrust; end
module Thrust::Android; end

misplaced_files = "../{codesign_wrapper,xcrun,thrust_config}.rb"
(Dir[File.expand_path(misplaced_files, __FILE__)] + Dir[File.expand_path("../thrust/**/**.rb", __FILE__)]).each do |file|
  require file
end
