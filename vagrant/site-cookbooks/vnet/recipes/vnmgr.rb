#
# Cookbook Name:: vnet_vnmgr
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "vnet::common"

node[:vnet][:packages][:vnmgr].each do |pkg|
  package pkg
end

# mysqld
service "mysqld" do
  action [:enable, :start]
end

# redis
execute "update_redis_conf" do
  command "sudo sed -i-e 's,^bind,#bind,' /etc/redis.conf"
end

service "redis" do
  action [:enable, :start]
end

# openvnet
template "/etc/openvnet/vnmgr.conf" do
  source "vnet.vnmgr.conf.erb"
  owner "root"
  group "root"
  variables({
    host: node[:vnet][:config][:vnmgr][:host],
    port: node[:vnet][:config][:vnmgr][:port],
  })
end
