require 'spec_helper'

describe Thrust::TestflightCredentials do
  it 'exposes the api_token' do
    credentials = Thrust::TestflightCredentials.new('api_token' => 'api-token')
    expect(credentials.api_token).to eq('api-token')
  end

  it 'exposes the team_token' do
    credentials = Thrust::TestflightCredentials.new('team_token' => 'team-token')
    expect(credentials.team_token).to eq('team-token')
  end
end
