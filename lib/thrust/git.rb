require 'colorize'

class Thrust::Git
  def initialize(thrust_executor, out)
    @thrust_executor = thrust_executor
    @out = out
  end

  def ensure_clean
    if ENV['IGNORE_GIT']
      @out.puts 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'.red
    else
      @out.puts 'Checking for clean working tree...'
      @thrust_executor.system_or_exit 'git diff-index --quiet HEAD'
    end
  end

  def current_commit
    @thrust_executor.capture_output_from_system('git log --format=format:%h -1').strip
  end

  def reset
    @thrust_executor.system_or_exit('git reset --hard')
  end

  def checkout_file(filename)
    @thrust_executor.system_or_exit("git checkout #{filename}")
  end

  def commit_summary_for_last_deploy(deployment_target)
    sha_of_latest_deployed_commit = latest_deployed_commit(deployment_target)
    if sha_of_latest_deployed_commit
      "#{deployment_target}:".blue + " #{summary_for_commit(sha_of_latest_deployed_commit)}"
    else
      "#{deployment_target}:".blue + ' Never deployed'
    end
  end

  def generate_notes_for_deployment(deployment_target)
    sha_of_latest_commit = @thrust_executor.capture_output_from_system('git rev-parse HEAD').strip
    sha_of_latest_deployed_commit = latest_deployed_commit(deployment_target)

    notes = Tempfile.new('deployment_notes')

    if sha_of_latest_deployed_commit
      @thrust_executor.system_or_exit("git log --oneline #{sha_of_latest_deployed_commit}...#{sha_of_latest_commit}", notes.path)
    else
      notes.puts(summary_for_commit(sha_of_latest_commit))
      notes.close
    end

    notes.path
  end

  private

  def summary_for_commit(sha)
    @thrust_executor.capture_output_from_system("git log --oneline -n 1 #{sha}")
  end

  def latest_deployed_commit(deployment_target)
    list = @thrust_executor.capture_output_from_system("autotag list #{deployment_target}")
    unless list.strip.empty?
      list.split("\n").last.split(" ").first
    end
  end
end
