require 'nori'

module Thrust
  class SchemeParser
    def parse_environment_variables(scheme, xcodeproj_path = nil)
      config = load_scheme(scheme, xcodeproj_path)

      env = {}

      if config['Scheme']['LaunchAction']['EnvironmentVariables']
        environment_variables = config['Scheme']['LaunchAction']['EnvironmentVariables']['EnvironmentVariable']
        environment_variables = [environment_variables] unless environment_variables.is_a?(Array)

        environment_variables.each do |environment_variable|
          if environment_variable['@isEnabled'] == 'YES'
           env[environment_variable['@key']] = environment_variable['@value']
          end
        end
      end

      env
    end

    private

    def load_scheme(scheme, xcodeproj_path)
      scheme_path = "**/#{scheme}.xcscheme"
      scheme_path = "#{xcodeproj_path}/#{scheme_path}" if xcodeproj_path

      scheme_file = Dir.glob(scheme_path).first
      parser = Nori.new(parser: :rexml)
      parser.parse(File.read(scheme_file))
    end
  end
end
