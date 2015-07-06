Gem::Specification.new do |s|
  s.name        = 'vnet_api_client'
  s.version     = '0.7'
  s.date        = '2015-07-15'
  s.summary     = 'Ruby wrapper for OpenVNet\'s RESTful API'
  s.description = s.summary
  s.authors     = ['Axsh Co. LTD']
  s.email       = 'dev@axsh.net'
  s.files       = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)
  s.homepage    = 'http://openvnet.org'
  s.license     = 'LGPLv3'

  s.required_ruby_version = '>= 2.1.1'
end
