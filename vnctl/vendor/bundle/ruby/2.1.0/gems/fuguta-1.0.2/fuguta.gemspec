$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'fuguta/version'
Gem::Specification.new do |s|
  s.name        = 'fuguta'
  s.version     = Fuguta::VERSION
  s.summary     = "A configuration framework for Ruby programs"
  s.description = "A configuration framework for Ruby programs"
  s.authors     = ["Axsh co. LTD"]
  s.homepage    = "https://github.com/axsh/fuguta"
  s.require_path = ['lib']
  s.files       = `git ls-files`.split($/)
end
