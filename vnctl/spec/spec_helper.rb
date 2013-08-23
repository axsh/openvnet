# -*- coding: utf-8 -*-

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter = :documentation
end

def vnctl(args)
  Dir.chdir(File.dirname(__FILE__) + "/..")
  # p "bin/vnctl #{args}"
  `bin/vnctl #{args}`
end
