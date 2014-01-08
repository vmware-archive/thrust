class Git
  def self.current_commit
    `git log --format=format:%h -1`.strip
  end

  def self.reset
  end
end