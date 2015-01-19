require 'rspec'
require 'stringio'
require 'timecop'
require 'tmpdir'
require 'tempfile'
require 'fakefs/safe'

require_relative '../lib/thrust'
require_relative 'lib/fake_executor'

RSpec.configure do |c|
  c.color = true

  c.before(:each) { FakeFS.activate! }
  c.before(:each) { FakeFS::FileSystem.clear }
  c.after(:each) { FakeFS.deactivate! }
end
