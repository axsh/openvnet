#
# Cookbook Name:: vnet_webapi
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "vnet::common"

template "/etc/openvnet/webapi.conf" do
  source "vnet.webapi.conf.erb"
  owner "root"
  group "root"
  variables({
    host: node[:vnet][:config][:webapi][:host],
    port: node[:vnet][:config][:webapi][:port],
  })
end
