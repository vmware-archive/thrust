require 'tmpdir'
require 'pathname'
require File.expand_path('../../../lib/ipa_re_signer', __FILE__)

describe IpaReSigner do
  def in_temp_dir(&block)
    Dir.mktmpdir do |temp_path|
      Dir.mkdir("#{temp_path}/Extra Path With Spaces")
      block.call Pathname("#{temp_path}/Extra Path With Spaces")
    end
  end

  let(:fixture_dir) {
    Pathname(File.expand_path("../../fixtures", __FILE__))
  }
  let(:ipa_path) {
    fixture_dir.join("Fake.ipa")
  }
  let(:output_swallower) {
    double('output', :puts => nil)
  }

  it "re-signs an existing IPA file" do
    begin
      in_temp_dir do |provision_search_path|
        File.open("#{provision_search_path}/fakey_provision.mobileprovision", "w") do |file|
          file << "Lovely Stuff"
        end

        identity = "iPhone Distribution: Fakey Fakester"
        provision_search_query = "Lovely Stuff"
        signer = double("Signer")

        re_signer = IpaReSigner.new(ipa_path,
                                    identity,
                                    provision_search_path,
                                    provision_search_query,
                                    signer,
                                    output_swallower)

        signer.should_receive(:call).with(identity, %r{Payload/Fake.app/ResourceRules.plist}, %r{Payload/Fake.app})
        re_signer.call

        `cd "#{provision_search_path}"; unzip #{fixture_dir.join("Fake.resigned.ipa")}`
        expect(File.exists?(provision_search_path.join("Payload/Fake.app/_CodeSignature/"))).to be_false
        expect(File.exists?(provision_search_path.join("Payload/Fake.app/CodeResources/"))).to be_false
        expect(File.read(provision_search_path.join("Payload/Fake.app/embedded.mobileprovision"))).to eq("Lovely Stuff")
      end
    ensure
      FileUtils.rm_f(fixture_dir.join("Fake.resigned.ipa"))
    end
  end

  it "aborts if no provisioning profile found" do
    in_temp_dir do |provision_search_path|
      identity = "iPhone Distribution: Fakey Fakester"
      provision_search_query = "I bet you can't find me"
      re_signer = IpaReSigner.new(ipa_path,
                                  "some identity",
                                  provision_search_path,
                                  provision_search_query,
                                  double('unused signer'),
                                  output_swallower)
      expect { re_signer.call }.to raise_exception(IpaReSigner::ProvisioningProfileNotFound)
    end
  end
end
