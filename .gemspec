# $ jgem build familiar.gemspec && jgem install ./familiar-0.0.0.gem 
Gem::Specification.new do |s|
  s.name        = 'familiar'
  s.version     = '0.0.0'
  s.date        = '2011-10-07'
  s.summary     = "Hey, this is familiar!"
  s.description = "Clojure RT for Ruby"
  s.authors     = ["Dave Ray"]
  s.email       = 'daveray@gmail.com'
  s.files       = ["lib/familiar.rb", 
                   "lib/clojure-1.3.0.jar"]
  s.homepage    = 'http://rubygems.org/gems/familiar'
end
