#
# Cookbook Name:: vnet_common
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "vnet::base"

node[:vnet][:packages][:common].each do |pkg|
  package pkg
end

# build openvswitch rpm
if node[:vnet][:repositry_server]
  bash "build_openvswitch_rpm" do
    code <<-EOS
      yum install -y make git gcc gcc-c++ rpm-build redhat-rpm-config rpmdevtools yum-utils python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r) createrepo
      REPO_BASE_DIR=/vagrant/repos /opt/axsh/openvnet/deployment/packagebuild/build_packages_third_party.sh openvnet-openvswitch
    EOS

    not_if { File.exists?("/vagrant/repos/packages/rhel/6/third_party/current/") }
  end
end

# rbenv
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

node[:vnet][:ruby_versions].each do |version|
  rbenv_ruby version do
    global version == node[:vnet][:ruby_global]
  end
 
  rbenv_gem "bundler" do
    ruby_version version
  end
end

file "/etc/sudoers.d/vagrant" do
  content <<-EOS
Defaults !secure_path
Defaults env_keep += "PATH RBENV_ROOT"
  EOS
end

# openvnet

directory "/opt/axsh"
git "/opt/axsh/openvnet" do
  repository "https://github.com/axsh/openvnet.git"
end

execute "chown -R vagrant:vagrant /opt/axsh/openvnet"

execute "make install-bundle-dev" do
  user "vagrant"
  cwd "/opt/axsh/openvnet"
end

execute "make update-config" do
  cwd "/opt/axsh/openvnet"
end

execute "replace RUBY_PATH" do
  command "sudo sed -i-e 's,RUBY_PATH=.*,RUBY_PATH=/opt/rbenv/shims,' /etc/default/openvnet"
end

template "/etc/openvnet/common.conf" do
  source "vnet.common.conf.erb"
  owner "root"
  group "root"
  variables({
    registry_host: node[:vnet][:config][:common][:registry_host],
    registry_port: node[:vnet][:config][:common][:registry_port],
    db_host: node[:vnet][:config][:common][:db_host],
    db_port: node[:vnet][:config][:common][:db_port],
  })
end
