require 'rake'

Gem::Specification.new do |s|
  s.name        = 'thrust'
  s.version     = '0.4.0'
  s.date        = '2013-07-24'
  s.summary     = 'Thrust is a collection of rake tasks for iOS/Android development and deployment'
  s.description = 'Thrust provides a collection of rake tasks for iOS and Android projects.  These include tasks for running Cedar test suites (iOS) and for deploying apps to Testflight (iOS and Android).'
  s.authors = [
    'Aaron Levine',
    'Aaron VonderHaar',
    'Andrew Bruce',
    'Andrew Kitchen',
    'Brandon Liu',
    'Brian Butz',
    'Can Berk Guder',
    'Eugenia Dellapenna',
    'Jeff Hui',
    'Joe Masilotti',
    'Johnathon Britz',
    'Jonathan Barnes',
    'Michael McCormick',
    'Molly Trombley-McCann',
    'Philip Kuryloski',
    'Rachel Bobbins',
    'Sheel Choksi',
    'Tyler Schultz',
    'Wiley Kestner'
  ]
  s.email       = 'mc+jbritz@pivotallabs.com'
  s.files       = FileList['lib/**/**.rb', 'lib/**/*.rake', 'lib/**/*.yml'].to_a
  s.homepage    = 'http://github.com/pivotal/thrust'
  s.default_executable = 'thrust'
  s.require_paths = ['lib']
  s.executables = ['thrust']
  s.license = 'MIT'
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'colorize', '~> 0.6'
  s.add_runtime_dependency 'auto_tagger', '~> 0.2'
  s.add_runtime_dependency 'rake', '~> 10.1'
  s.add_development_dependency 'fakefs', '~> 0.5'
  s.add_development_dependency 'rspec', '2.14'
  s.add_development_dependency 'timecop', '~> 0.7'
end
