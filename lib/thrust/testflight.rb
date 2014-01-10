class Thrust::Testflight
  def initialize(out, input, api_token, team_token)
    @out = out
    @in = input
    @api_token = api_token
    @team_token = team_token
  end

  def upload(build_directory, app_name, ipa_file, notify, distribution_list = nil)
    @out.puts 'Zipping dSYM...'
    dsym_path = "#{build_directory}/#{app_name}.app.dSYM"
    zipped_dsym_path = "#{dsym_path}.zip"
    Thrust::Executor.system_or_exit "zip -r -T -y '#{zipped_dsym_path}' '#{dsym_path}'"
    @out.puts 'Done!'

    message_file_path = Thrust::UserPrompt.get_user_input('Deploy Notes: ', @out, @in)

    Thrust::Executor.system_or_exit [
    'curl http://testflightapp.com/api/builds.json',
    "-F file=@#{ipa_file}",
    "-F dsym=@#{zipped_dsym_path}",
    "-F api_token='#{@api_token}'",
    "-F team_token='#{@team_token}'",
    "-F notes=@#{message_file_path}",
    "-F notify=#{(ENV['NOTIFY'] || notify).to_s.downcase.capitalize}",
    ("-F distribution_lists='#{distribution_list}'" if distribution_list)
    ].compact.join(' ')
  end
end
