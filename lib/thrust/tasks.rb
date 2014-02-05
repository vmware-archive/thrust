load File.expand_path("../../tasks/cedar.rake", __FILE__) unless File.exists?('AndroidManifest.xml')
load File.expand_path("../../tasks/testflight.rake", __FILE__)
load File.expand_path("../../tasks/version.rake", __FILE__)
