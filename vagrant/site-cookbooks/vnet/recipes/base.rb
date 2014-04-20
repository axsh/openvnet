# yum
include_recipe "yum-epel"

# ntp
node.default[:ntp][:servers] = node[:vnet][:ntp_servers]
include_recipe "ntp"

node[:vnet][:packages][:base].each do |pkg|
  package pkg
end

# ssh
file "/home/vagrant/.ssh/id_rsa" do
  owner "vagrant"
  group "vagrant"
  mode "0600"
  content ::File.open("/vagrant/share/ssh/id_rsa").read
end

file "/home/vagrant/.ssh/config" do
  owner "vagrant"
  group "vagrant"
  mode "0600"
  content ::File.open("/vagrant/share/ssh/vnet_config").read
end

# timezone
file "/etc/localtime" do
  owner "root"
  group "root"
  content ::File.open("/usr/share/zoneinfo/Japan").read
  action :create
end

# network interface
node[:vnet][:interfaces].each do |interface|
  template "/etc/sysconfig/network-scripts/ifcfg-#{interface[:device]}" do
    source "ifcfg.erb"
    owner "root"
    group "root"
    variables interface
  end

  execute "ifdown #{interface[:device]}"
  execute "ifup #{interface[:device]}"
end
