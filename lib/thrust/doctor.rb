require 'colorize'

module Thrust
  class Doctor
    def initialize(out)
      @out = out
    end

    def run()
      unless File.exists?('thrust.yml')
        @out.puts "ERROR: ".red
        @out.puts
      end
      unless File.exists?('Specs')
        @out.puts "thrust: ERROR: Missing Specs directory".red
        @out.puts "thrust: DO IT: mkdir Specs".green
      end
    end
  end
end