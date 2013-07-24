require 'rake'

Gem::Specification.new do |s|
  s.name        = 'thrust'
  s.version     = '0.0.5'
  s.date        = '2013-07-24'
  s.summary     = 'iOS raketasks'
  s.description = ''
  s.authors     = ['Michael McCormick', 'Johnathon Britz', 'Jonathan Barnes', 'Andrew Kitchen', 'Tyler Schultz', 'Wiley Kestner', 'Brandon Liu', 'Jeff Hui', 'Philip Kuryloski']
  s.email       = 'mc+jbritz@pivotallabs.com'
  s.files       = FileList['lib/**/*.rb', 'lib/**/*.rake', 'lib/**/*.yml'].to_a
  s.homepage    = 'http://github.com/dipolesource/thrust'
  s.executables << 'thrust'
end
