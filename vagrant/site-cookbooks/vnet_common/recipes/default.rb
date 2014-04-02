#
# Cookbook Name:: vnet_common
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# ssh
file "/home/vagrant/.ssh/id_rsa" do
  owner "vagrant"
  group "vagrant"
  mode "0600"
  content ::File.open("/vagrant/vm/ssh/id_rsa").read
end

# yum
include_recipe "yum"
include_recipe "yum-epel"

# ntp
include_recipe "ntp"

# timezone
file "/etc/localtime" do
  owner "root"
  group "root"
  content ::File.open("/usr/share/zoneinfo/Japan").read
  action :create
end

## network
#template "/etc/sysconfig/network-scripts/ifcfg-eth1" do
#  source "ifcfg.erb"
#  owner "root"
#  group "root"
#  variables({
#    device: "eth1",
#    onboot: "yes",
#    bootproto: "static",
#    target: node["vnet_common"]["management_network"]["ipaddr"],
#    mask: node["vnet_common"]["management_network"]["mask"],
#    gateway: node["vnet_common"]["management_network"]["gateway"],
#  })
#end

# openvnet third party repository
yum_repository "openvnet_third_party" do
  baseurl node["vnet_common"]["openvnet_third_party_repository_url"]
  gpgcheck false
end

node["vnet_common"]["packages"].each do |pkg|
  package pkg
end

# rbenv
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

node["vnet_common"]["ruby_versions"].each do |version|
  rbenv_ruby version do
    global version == node["vnet_common"]["ruby_global"]
  end
 
  rbenv_gem "bundler" do
    ruby_version version
  end
end

# openvnet

execute "make update-config" do
  cwd node["vnet_common"]["vnet_path"]
end

execute "replace RUBY_PATH" do
  command "sudo sed -i-e 's,RUBY_PATH=.*,RUBY_PATH=/opt/rbenv/shims,' /etc/default/openvnet"
end

template "/etc/openvnet/common.conf" do
  cookbook "vnet_common"
  source "vnet.common.conf.erb"
  owner "root"
  group "root"
  variables({
    registry_host: node["vnet_common"]["config"]["registry_host"],
    registry_port: node["vnet_common"]["config"]["registry_port"],
    db_host: node["vnet_common"]["config"]["db_host"],
    db_port: node["vnet_common"]["config"]["db_port"],
  })
end
