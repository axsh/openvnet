# -*- coding: utf-8 -*-

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter = :documentation
end

def vnctl(args)
  Dir.chdir(File.dirname(__FILE__) + "/..")
  res = `bin/vnctl #{args}`
  res.should_not eq("<h1>Internal Server Error</h1>\n")
  res_array = res.split("\n").map { |line| eval(line) }
  if res_array.size == 1
    res_array[0]
  else
    res_array
  end
end
