module Thrust
  class TestflightCredentials
    attr_reader :api_token,
                :team_token

    def initialize(attributes)
      @api_token = attributes['api_token']
      @team_token = attributes['team_token']
    end
  end
end
