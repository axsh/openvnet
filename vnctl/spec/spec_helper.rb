# -*- coding: utf-8 -*-

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter = :documentation
end

def vnctl(args)
  Dir.chdir(File.dirname(__FILE__) + "/..")
  res = `bin/vnctl #{args}`
  res.should_not eq("<h1>Internal Server Error</h1>\n")
  res
end
