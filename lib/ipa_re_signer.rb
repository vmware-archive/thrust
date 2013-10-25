require 'pathname'
require 'tmpdir'
require File.expand_path('../codesign_wrapper', __FILE__)

class IpaReSigner
  ProvisioningProfileNotFound = Class.new(StandardError)

  attr_reader :ipa_path, :identity, :provision_search_path, :provision_search_query, :signer

  def self.make(ipa_path, identity, provision_search_query)
    provision_search_path = File.expand_path("~/Library/MobileDevice/Provisioning Profiles/")
    new(ipa_path, identity, provision_search_path, provision_search_query, CodesignWrapper.new, $stdout)
  end

  def initialize(ipa_path, identity, provision_search_path, provision_search_query, signer, output)
    @ipa_path = ipa_path
    @identity = identity
    @provision_search_path = provision_search_path
    @provision_search_query = provision_search_query
    @signer = signer
    @output = output
  end

  def call
    Dir.mktmpdir do |tmpdir|
      execute "unzip -q #{ipa_path} -d #{tmpdir}"
      execute "cd #{tmpdir}; rm -rf Payload/#{app_name}.app/{_CodeSignature,CodeResources}"
      execute %Q(cp "#{provision_path}" #{tmpdir}/Payload/#{app_name}.app/embedded.mobileprovision)
      signer.call(identity, "#{tmpdir}/Payload/#{app_name}.app/ResourceRules.plist", "#{tmpdir}/Payload/#{app_name}.app")
      execute "cd #{tmpdir}; zip -qr #{resigned_ipa_path} Payload"
    end
  end

  private

  def execute(command)
    @output.puts command
    system command
  end

  def provision_path
    command = %Q(grep -rl "#{provision_search_query}" "#{provision_search_path}")
    paths = `#{command}`.split("\n")
    paths.first or raise(ProvisioningProfileNotFound, "\nCouldn't find provisioning profiles matching #{provision_search_query}.\n\nThe command used was:\n\n#{command}")
  end

  def ipa_filename
    File.basename ipa_path
  end

  def resigned_ipa_path
    ipa_dir.join("#{app_name}.resigned.ipa")
  end

  def app_name
    File.basename(ipa_path, File.extname(ipa_path))
  end

  def ipa_dir
    Pathname(File.dirname(ipa_path))
  end
end
