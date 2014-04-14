require 'colorize'

module Thrust
  class UserPrompt
    def self.get_user_input(prompt, fout, fin)
      fout.print(prompt.yellow)
      message = fin.gets
      message_file = Tempfile.new('message')
      message_file << message
      message_file.close
      message_file.path
    end
  end
end
