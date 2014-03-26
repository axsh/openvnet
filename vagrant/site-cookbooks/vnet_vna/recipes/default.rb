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

template "/etc/sysconfig/network-scripts/ifcfg-br1" do
  cookbook "vnet_common"
  source "ifcfg.erb"
  owner "root"
  group "root"
  variables({
    device: "br1",
    onboot: "yes",
    device_type: "ovs",
    type: "OVSBridge",
    bootproto: "static",
    target: "10.50.0.2",
    mask: "255.255.255.0",
  })
  notifies :run, "execute[restart_network]", :immediately
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
  notifies :run, "execute[restart_network]", :immediately
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

# docker

include_recipe "docker"

# pipework
execute "yum install -y http://rdo.fedorapeople.org/openstack/openstack-havana/rdo-release-havana.rpm || :"

package "iproute" do
  action :upgrade
end

#directory "/opt/jpetazzo"
#git "/opt/jpetazzo/pipework" do
#  repository "https://github.com/jpetazzo/pipework.git"
#end

image_name = "#{node[:vnet_vna][:docker][:registry]}/vmbase"

vms = data_bag('vms').map { |id| data_bag_item('vms', id) }.select do |vm|
  vm["host"] == node.name
end

if node[:vnet_vna][:docker][:cleanup]
  vms.each do |vm|
    bash "rm_vm" do
      code <<-EOS
        docker stop #{vm["id"]} > /dev/null 2>&1 || :
        docker rm #{vm["id"]} > /dev/null 2>&1 || :
      EOS
    end
  end

  bash "rmi_vm_image" do
    code <<-EOS
      docker rmi #{image_name} > /dev/null
    EOS
  end
end

vms.each do |vm|
  bash "run_vm" do
    code <<-EOS
      docker run -d --name #{vm["id"]} #{image_name}
    EOS
    not_if "docker inspect #{vm["id"]}"
  end

  # cleanup interfaces
  bash "restart_vm" do
    code <<-EOS
      docker restart #{vm["id"]}
    EOS
  end

  vm["interfaces"].each do |interface|
    ip_address = interface["ip_address"]
    mask = interface["mask"] || 24
    unless ip_address
      ip_address = 0
      mask = 0
    end
    bash "configure_vm_network" do
      cwd "/vagrant/vm"
      code <<-EOS
        ./pipework #{interface["bridge"]} \
          -i #{interface["name"]} \
          -p #{interface["port_name"]} \
          #{vm["id"]} \
          #{ip_address}/#{mask} \
          #{interface["mac_address"]}
      EOS
    end
  end
end
