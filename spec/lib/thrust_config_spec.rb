require 'tmpdir'
require 'tempfile'
require 'fileutils'
require File.expand_path('../../../lib/thrust_config', __FILE__)

describe "testflight deploy" do
  it "makes an IPA file" do
    config = {
      "thrust_version" => 0.1,
      "project_name" => "Fake",
      "app_name" => "Fake",
      "identity" => "iPhone Distribution: Fair Identity",

      "sim_binary" => 'Specs/bin/ios-sim',
      "spec_targets" => {
        "specs" => {
          "name" => "Specs",
          "configuration" => "Release",
          "target" => "Specs",
          "sdk" => 7.0,

          "api_token" => "jgrkrjngkrjnrgoiwoiwoiwwoiwoiwoiwoiwoiwowiwoi",
          "distributions" => {
            "fake_distribution" => {
              "token" => "asdfasdfasdf",
              "default_list" => "FakeList",
              "configuration" => "AdHoc",
            }
          }
        }
      }
    }

    Dir.mktmpdir do |build_parent|
      build_dir = "#{build_parent}/build/AdHoc-iphoneos"
      FileUtils.mkdir_p build_dir
      FileUtils.cp_r(File.expand_path("../../fixtures/Fake.app", __FILE__), build_dir)
      runner = double('xcrun')
      config = ThrustConfig.new(build_parent, config, runner)

      runner.stub(:call).
        with(build_dir, 'Fake', "iPhone Distribution: Fair Identity").
        and_return("ipa_path")

      expect(config.xcode_package("AdHoc")).to eq("ipa_path")
    end
  end

end
