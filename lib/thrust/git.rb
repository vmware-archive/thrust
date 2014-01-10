class Thrust::Git
  def initialize(out)
    @out = out
  end

  def ensure_clean
    if ENV['IGNORE_GIT']
      @out.puts 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'
    else
      @out.puts 'Checking for clean working tree...'
      Thrust::Executor.system_or_exit 'git diff-index --quiet HEAD'
    end
  end

  def current_commit
    Thrust::Executor.capture_output_from_system('git log --format=format:%h -1').strip
  end

  def reset
    Thrust::Executor.system_or_exit('git reset --hard')
  end

  def commit_with_message(message, &block) #TODO: test
    if ENV['IGNORE_GIT']
      STDERR.puts 'WARNING NOT CHECKING FOR CLEAN WORKING DIRECTORY'
      block.call
    else
      ensure_clean
      STDERR.puts 'Checking that the master branch is up to date...'
      Thrust::Executor.system_or_exit 'git fetch && git diff --quiet HEAD origin/master'
      block.call
      Thrust::Executor.system_or_exit "git commit -am \"#{message}\" && git push origin head"
    end
  end
end
