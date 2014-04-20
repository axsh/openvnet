#
# Cookbook Name:: vnet_vna
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "vnet::common"

# openvnet third party repository
yum_repository "openvnet_third_party" do
  baseurl node[:vnet][:openvnet_third_party_repository_url]
  gpgcheck false
end

# rdo repository
execute "yum install -y http://rdo.fedorapeople.org/openstack/openstack-havana/rdo-release-havana.rpm || :"

bash "disable rdo-release" do
  code "sed -i -e 's/enabled=1/enabled=0/' /etc/yum.repos.d/rdo-release.repo"
end

# install packages
node[:vnet][:packages][:vna].each do |pkg|
  package pkg
end

# upgrade iproute2
package "iproute" do
  action :upgrade
  options "--enablerepo=openstack-havana"
end

# docker
package "docker-io" do
  action ["install"]
end

group "docker" do
  members %w(vagrant)
  action [:create, :manage]
end

service 'docker' do
  supports :status => true, :restart => true, :reload => true
  action [:start]
end


# openvswitch
package "openvswitch" do
  action :upgrade
  options "--enablerepo=openstack-havana"
end

service "openvswitch" do
  supports :enable => true, :status => true, :start => true
  action [:start]
end

# network settings
bridge_name = node[:vnet][:vna][:ovs_bridge]

template "/etc/sysconfig/network-scripts/ifcfg-#{bridge_name}" do
  source "ifcfg.erb"
  owner "root"
  group "root"
  variables({
    device: bridge_name,
    onboot: "yes",
    device_type: "ovs",
    type: "OVSBridge",
    bootproto: "none",
    target: node[:vnet][:vna][:datapath][:ipaddr],
    mask: node[:vnet][:vna][:datapath][:mask],
    ovs_extra: <<EOS
"
 set bridge     ${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     ${DEVICE} other_config:disable-in-band=true --
 set bridge     ${DEVICE} other-config:datapath-id=#{node[:vnet][:vna][:datapath][:datapath_id]} --
 set bridge     ${DEVICE} other-config:hwaddr=#{node[:vnet][:vna][:datapath][:hwaddr]} --
 set-fail-mode  ${DEVICE} standalone --
 set-controller ${DEVICE} tcp:127.0.0.1:6633
"
 #set-controller ${DEVICE} unix:/var/run/openvswitch/${DEVICE}.controller
 #set-fail-mode  ${DEVICE} secure --
EOS
  })
end


node[:vnet][:vna][:ovs_ports].each do |port|
  template "/etc/sysconfig/network-scripts/ifcfg-#{port}" do
    source "ifcfg.erb"
    owner "root"
    group "root"
    variables({
      device: "#{port}",
      onboot: "yes",
      device_type: "ovs",
      type: "OVSPort",
      ovs_bridge: bridge_name,
      bootproto: "none",
    })
  end
end

#service "network" do
#  supports :status => true, :restart => true
#  action [:restart]
#end

#execute "restart_network" do
#  ignore_failure true
#  command "service network restart"
#end

bash "restart_network" do
  code [
    "ifdown #{bridge_name}",
    *node[:vnet][:vna][:ovs_ports].map {|port| "ifdown #{port}" },
    *node[:vnet][:vna][:ovs_ports].map {|port| "ifup #{port}" },
  ].join("\n")
end

node[:vnet][:vna][:routes].each do |r|
  route r[:target] do
    gateway r[:gateway]
    device r[:device]
  end
end

template "/etc/openvnet/vna.conf" do
  source "vnet.vna.conf.erb"
  owner "root"
  group "root"
  variables({
    id: node[:vnet][:config][:vna][:id],
    host: node[:vnet][:config][:vna][:host],
    port: node[:vnet][:config][:vna][:port],
  })
end

# pipework
#directory "/opt/jpetazzo"
#git "/opt/jpetazzo/pipework" do
#  repository "https://github.com/jpetazzo/pipework.git"
#end

# udhcpc
link "/sbin/udhcpc" do
  to "/vagrant/share/bin/udhcpc"
end

data_bag(:vms).map { |id| data_bag_item(:vms, id) }.select { |vm|
  vm["host"] == node.name
}.tap do |vms|

  unless vms.empty?
    if node[:vnet][:vna][:docker][:registry]
      base_name = "#{node[:vnet][:vna][:docker][:registry]}/centos"
    
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
        #docker stop #{vm["id"]} > /dev/null 2>&1 || :
        #docker rm #{vm["id"]} > /dev/null 2>&1 || :
        docker stop #{vm["id"]} || :
        docker rm #{vm["id"]} || :
        sudo -u vagrant ssh-keygen -R [localhost]:#{vm["ssh_port"]} 2>&1 ||:
      EOS
    end
  end
    
  unless vms.empty?
    bash "build_vmbase" do
      code <<-EOS
        #service docker restart # workaround
        docker build -t vmbase --rm /vagrant/share
      EOS
    end
  end
    
  vms.each do |vm|
    bash "run_vm" do
      code <<-EOS
        docker run -d -t --dns 127.0.0.1 -h #{vm["id"]} -p #{vm["ssh_port"]}:22 --name #{vm["id"]} vmbase
        docker stop #{vm["id"]}
      EOS
    end
  end
end
