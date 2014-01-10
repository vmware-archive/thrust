module Thrust; end

misplaced_files = "../{codesign_wrapper,ipa_re_signer,xcrun,thrust_config}.rb"
(Dir[File.expand_path(misplaced_files, __FILE__)] + Dir[File.expand_path("../thrust/**/**.rb", __FILE__)]).each do |file|
  require file
end
