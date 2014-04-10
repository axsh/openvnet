#!/usr/bin/env ruby

require 'optparse'

params = ARGV.getopts("y")
config_file = File.join(Dir.home, ".ssh/config")
nodes = %w(vnmgr vna1 vna2 vna3 edge legacy router registry)
str_begin = "### vnet vagrant config begin ###"
str_end = "### vnet vagrant config end ###"
regexp = /#{str_begin}.*#{str_end}/m

config = [].tap { |str|
  str << str_begin
  str << ""
  nodes.each do |node|
    str << %x(vagrant ssh-config #{node})
  end
  str << str_end
}.join("\n")

puts config

unless params["y"]
  print "overwrite ssh config?[Y/n]"
  
  gets.chomp.tap do |ans|
    exit 0 if !ans.empty? && ans !~ /^[Yy]/
  end
end

File.open(config_file, "r+") do |file|
  body = file.read
  if body =~ regexp
    body.sub!(regexp, config)
    file.rewind
    file.puts body
    file.truncate(file.tell)
  else
    file.puts
    file.puts config
  end
end
