#
# Cookbook Name:: vnet_router
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node[:vnet][:packages][:router].each do |pkg|
  package pkg
end

#sysctl_param 'net.ipv4.ip_forward' do
#  value 1
#end
node.default[:sysctl][:params][:net][:ipv4][:ip_forward] = 1
include_recipe "sysctl"

node[:vnet][:router][:ifconfig].each do |i|
  bash "ifconfig #{i[:device]} down"
  ifconfig i[:target] do
    device i[:device]
    mask i[:mask] || "255.255.255.0"
  end
end
