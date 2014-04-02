#
# Cookbook Name:: vnet_vna
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "vnet_common"

node[:vnet_vna][:packages].each do |pkg|
  package pkg
end

# openvswitch
service "openvswitch" do
  supports :enable => true, :status => true, :start => true
  action [:start]
end

# network settings
template "/etc/sysconfig/network-scripts/ifcfg-br0" do
  cookbook "vnet_common"
  source "ifcfg.erb"
  owner "root"
  group "root"
  variables({
    device: "br0",
    onboot: "yes",
    device_type: "ovs",
    type: "OVSBridge",
    bootproto: "static",
    target: node[:vnet_vna][:datapath][:ipaddr],
    mask: node[:vnet_vna][:datapath][:mask],
    ovs_extra: <<EOS
"
 set bridge     ${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     ${DEVICE} other_config:disable-in-band=true --
 set bridge     ${DEVICE} other-config:datapath-id=#{node[:vnet_vna][:datapath][:datapath_id]} --
 set bridge     ${DEVICE} other-config:hwaddr=#{node[:vnet_vna][:datapath][:hwaddr]} --
 set-fail-mode  ${DEVICE} standalone --
 set-controller ${DEVICE} tcp:127.0.0.1:6633
"
 #set-controller ${DEVICE} unix:/var/run/openvswitch/${DEVICE}.controller
 #set-fail-mode  ${DEVICE} secure --
EOS
  })
end

template "/etc/sysconfig/network-scripts/ifcfg-eth2" do
  cookbook "vnet_common"
  source "ifcfg.erb"
  owner "root"
  group "root"
  variables({
    device: "eth2",
    onboot: "yes",
    device_type: "ovs",
    type: "OVSPort",
    ovs_bridge: "br0",
    bootproto: "none",
  })
end

execute "restart_network" do
  ignore_failure true
  command "service network restart"
end

#service "network" do
#  supports :status => true, :restart => true
#  action [:restart]
#end

template "/etc/openvnet/vna.conf" do
  source "vnet.vna.conf.erb"
  owner "root"
  group "root"
  variables({
    id: node[:vnet_vna][:config][:id],
    host: node[:vnet_vna][:config][:host],
    port: node[:vnet_vna][:config][:port],
  })
end

## upgrade docker to 0.9
#execute "yum install -y http://dl.fedoraproject.org/pub/epel/testing/6/x86_64/docker-io-0.9.0-3.el6.x86_64.rpm || :"

# upgrade iproute2
execute "yum install -y http://rdo.fedorapeople.org/openstack/openstack-havana/rdo-release-havana.rpm || :"
package "iproute" do
  action :upgrade
end

# docker
package "docker-io" do
  action ["install"]
end

#file "/var/run/docker.pid" do
#  action :delete
#end

service 'docker' do
  supports :status => true, :restart => true, :reload => true
  action [:start, :enable]
end

group "docker" do
  members %w(vagrant)
  action [:create, :manage]
end

# pipework
#directory "/opt/jpetazzo"
#git "/opt/jpetazzo/pipework" do
#  repository "https://github.com/jpetazzo/pipework.git"
#end

# udhcpc
link "/sbin/udhcpc" do
  to "/vagrant/vm/bin/udhcpc"
end

vms = node[:vnet_vna][:vms].select do |vm|
  vm["host"] == node.name
end

unless vms.empty?
  if node[:vnet_vna][:docker][:registry]
    base_name = "#{node[:vnet_vna][:docker][:registry]}/centos"
  
    bash "create_image" do
      code <<-EOS
        docker pull #{base_name}
        docker tag #{base_name} centos
      EOS
    end
  end
end
  
vms.each do |vm|
  bash "rm_vm" do
    code <<-EOS
      #docker stop #{vm["name"]} > /dev/null 2>&1 || :
      #docker rm #{vm["name"]} > /dev/null 2>&1 || :
      docker stop #{vm["name"]} || :
      docker rm #{vm["name"]} || :
      sudo -u vagrant ssh-keygen -R [localhost]:#{vm["ssh_port"]}
    EOS
  end
end
  
unless vms.empty?
  bash "build_vmbase" do
    code <<-EOS
      docker build -t vmbase --rm /vagrant/vm
    EOS
  end
end
  
vms.each do |vm|
  bash "run_vm" do
    code <<-EOS
      docker run -d -t -dns 127.0.0.1 -h #{vm["name"]} -p #{vm["ssh_port"]}:22 --name #{vm["name"]} vmbase
    EOS
    not_if "docker inspect #{vm["name"]}"
  end

  # cleanup interfaces
  bash "restart_vm" do
    code <<-EOS
      docker restart #{vm["name"]}
    EOS
  end
end
