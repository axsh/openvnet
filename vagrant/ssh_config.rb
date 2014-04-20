#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'
require 'json'

default_options = {
  assume_yes: false,
  identity_file: File.join(Dir.home, ".vagrant.d/insecure_private_key")
}

options = default_options.dup

OptionParser.new.tap do |opt|
  opt.on("-y") {|v| options[:assume_yes] = true }
  opt.on("-i IDENTITY_FILE") {|v| options[:identity_file] = v }
  opt.parse!(ARGV)
end

config_file = File.join(Dir.home, ".ssh/config")
share_dir = File.expand_path("./share", File.dirname(__FILE__))
ssh_dir = File.expand_path("./share/ssh", File.dirname(__FILE__))
node_dir = File.expand_path("./nodes", File.dirname(__FILE__))
data_bag_dir = File.expand_path("./data_bags", File.dirname(__FILE__))

str_begin = "### vnet vagrant config begin ###"
str_end = "### vnet vagrant config end ###"
regexp = /#{str_begin}.*#{str_end}/m

hosts = []

# create authorized_keys
%x(ssh-keygen -y -f #{options[:identity_file]} > #{ssh_dir}/authorized_keys)

# forward agent
%x(ssh-add #{options[:identity_file]})

Dir.glob("#{node_dir}/*.json") do |filename|
  name = filename.sub(%r!.*/nodes/(.*)\.json!, '\1')
  node = JSON.parse(File.read(filename))

  hosts << {
    name: name,
    hostname: node["vnet"]["interfaces"].first["target"],
  }
end

Dir.glob("#{data_bag_dir}/vms/*.json") do |filename|
  name = filename.sub(%r!.*/nodes/(.*)\.json!, '\1')
  vm = JSON.parse(File.read(filename))

  hosts << {
    name: vm["id"],
    hostname: vm["host"],
    port: vm["ssh_port"],
  }
end

base_config = <<-EOS
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
PasswordAuthentication no
LogLevel FATAL
ForwardAgent yes
EOS

File.open("#{ssh_dir}/vm_config", "w+") do |file|
  file.puts(base_config)
end

File.open("#{ssh_dir}/vnet_config", "w+") do |file|
  config = base_config

  hosts.sort_by { |h| h[:id] }.each do |host|
    config += <<-EOS

Host #{host[:name]}
  HostName #{host[:hostname]}
  Port #{host[:port] || 22}
  User vagrant
    EOS
  end

  file.puts config
end

host_config = [].tap { |str|
  str << str_begin
  hosts.sort_by { |h| h[:name] }.each do |host|
    str << <<-EOS

Host #{host[:name]}
  HostName #{host[:hostname]}
  Port #{host[:port] || 22}
  User vagrant
  IdentityFile #{options[:identity_file]}
  IdentitiesOnly yes
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  LogLevel FATAL
  ForwardAgent yes
    EOS
  end
  str << str_end
}.join("\n")


puts host_config

unless options[:assume_yes]
  print "overwrite ssh config?[Y/n]"
  
  gets.chomp.tap do |ans|
    exit 0 if !ans.empty? && ans !~ /^[Yy]/
  end
end

File.open(config_file, "r+") do |file|
  body = file.read
  if body =~ regexp
    body.sub!(regexp, host_config)
    file.rewind
    file.puts body
    file.truncate(file.tell)
  else
    file.puts
    file.puts host_config
  end
end
