include_recipe "vnet::base"

#sysctl_param 'net.ipv4.ip_forward' do
#  value 1
#end
node.default[:sysctl][:params][:net][:ipv4][:ip_forward] = 1
include_recipe "sysctl"
