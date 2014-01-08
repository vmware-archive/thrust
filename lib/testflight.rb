class Testflight
  def self.upload(ipa_file, zipped_dsym_path, api_token, team_token, message_file, notify, distribution_list)
    # @thrust.config['api_token']
#notify = (ENV['NOTIFY'] || notify).downcase.capitalize
    thrust.system_or_exit [
     "curl http://testflightapp.com/api/builds.json",
     "-F file=@#{ipa_file}",
     "-F dsym=@#{zipped_dsym_path}",
     "-F api_token='#{api_token}'",
     "-F team_token='#{team_token}'",
     "-F notes=@#{message_file.path}",
     "-F notify=#{notify}",
     ("-F distribution_lists='#{distribution_list}'" if distribution_list)
    ].compact.join(' ')
  end
end
