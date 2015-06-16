# yum
include_recipe "yum-epel"

# ntp
node.default[:ntp][:servers] = node[:vnet][:ntp_servers]
include_recipe "ntp"

node[:vnet][:packages][:base].each do |pkg|
  package pkg
end

file "/home/vagrant/.ssh/vnet_private_key" do
  owner "vagrant"
  group "vagrant"
  mode "0600"
  content ::File.open("/vagrant/share/ssh/vnet_private_key").read
end

bash "add_private_key_to_authorized_keys" do
  code <<-EOS
    cat /vagrant/share/ssh/vnet_private_key.pub >> /home/vagrant/.ssh/authorized_keys 
  EOS

  not_if 'grep "$(cat /vagrant/share/ssh/vnet_private_key.pub)" /home/vagrant/.ssh/authorized_keys'
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
