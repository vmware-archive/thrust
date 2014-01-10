module Thrust::UserPrompt
  def self.get_user_input(prompt, out, stdin = $stdin)
    out.print prompt
    message = stdin.gets
    message_file = Tempfile.new('message')
    message_file << message
    message_file.close
    message_file.path
  end
end