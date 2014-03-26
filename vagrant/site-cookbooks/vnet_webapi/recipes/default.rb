#
# Cookbook Name:: vnet_webapi
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

template "/etc/openvnet/webapi.conf" do
  source "vnet.webapi.conf.erb"
  owner "root"
  group "root"
  variables({
    host: node["vnet_webapi"]["config"]["host"],
    port: node["vnet_webapi"]["config"]["port"],
  })
end
