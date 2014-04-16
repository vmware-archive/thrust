class Thrust::FakeExecutor
  attr_reader :system_or_exit_history, :system_history

  def initialize
    @system_or_exit_history = []
    @system_history = []
    @outputs_for_commands = {}
  end

  def on_next_system_or_exit(&block)
    @on_next_system_or_exit = block
  end

  def register_output_for_cmd(output, cmd)
    @outputs_for_commands[cmd] = output
  end

  def system_or_exit(cmd, output_file = nil, env = {})
    @system_or_exit_history << {cmd: cmd, output_file: output_file}
    if @on_next_system_or_exit
      @on_next_system_or_exit.call(cmd, output_file)
      @on_next_system_or_exit = nil
    end
  end

  def system(cmd, output_file = nil)
    @system_history << {cmd: cmd, output_file: output_file}
  end

  def capture_output_from_system(cmd)
    @outputs_for_commands[cmd]
  end

  def check_command_for_failure(cmd)
    raise "not supported"
  end
end
