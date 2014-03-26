default[:vnet_vna][:packages] = %w(
openvswitch
)

#override[:docker][:group_members] = %w(vagrant)

default[:vnet_vna][:datapath][:ipaddr] = nil
default[:vnet_vna][:datapath][:mask] = "255.255.255.0"
default[:vnet_vna][:datapath][:datapath_id] = nil
default[:vnet_vna][:datapath][:hwaddr] = nil

default[:vnet_vna][:config][:id] = "vna"
default[:vnet_vna][:config][:host] = "127.0.0.1"
default[:vnet_vna][:config][:port] = 9103

default[:vnet_vna][:docker][:registry] = "192.168.20.20:5000"
default[:vnet_vna][:docker][:cleanup] = false
