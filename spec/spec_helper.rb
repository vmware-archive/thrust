require 'rspec'
require 'stringio'
require 'timecop'
require 'tmpdir'
require 'fakefs/safe'

require_relative '../lib/thrust'

RSpec.configure do |c|
  c.before(:all) { ENV['ANDROID_HOME'] = '/fake/android_home' }
end
