default[:vnet][:ntp_servers] = %w(
ntp1.jst.mfeed.ad.jp
ntp2.jst.mfeed.ad.jp
ntp3.jst.mfeed.ad.jp
)

default[:vnet][:repositry_server] = false

default[:vnet][:ruby_versions] = %w(2.1.1)
default[:vnet][:ruby_global] = "2.1.1"

# packages
default[:vnet][:packages][:common] = %w(
zeromq-devel
libpcap-devel
sqlite-devel
mysql-devel
)

default[:vnet][:packages][:vnmgr] = %w(
mysql-server
redis
)

default[:vnet][:packages][:vna] = %w(
busybox
)

default[:vnet][:packages][:base] = %w(
vim-enhanced
tcpdump
telnet
nc
bind-utils
man
inotify-tools
)

# config
default[:vnet][:config][:common][:registry_host] = "127.0.0.1"
default[:vnet][:config][:common][:registry_port] = 6379
default[:vnet][:config][:common][:db_host] = "localhost"
default[:vnet][:config][:common][:db_port] = 3306

default[:vnet][:config][:vnmgr][:host] = "127.0.0.1"
default[:vnet][:config][:vnmgr][:port] = 9102

default[:vnet][:config][:webapi][:host] = "127.0.0.1"
default[:vnet][:config][:webapi][:port] = 9101

default[:vnet][:config][:vna][:id] = "vna"
default[:vnet][:config][:vna][:host] = "127.0.0.1"
default[:vnet][:config][:vna][:port] = 9103

# vna
default[:vnet][:vna][:datapath][:ipaddr] = nil
default[:vnet][:vna][:datapath][:mask] = "255.255.255.0"
default[:vnet][:vna][:datapath][:datapath_id] = nil
default[:vnet][:vna][:datapath][:hwaddr] = nil
default[:vnet][:vna][:ovs_bridge] = "br0"
default[:vnet][:vna][:ovs_ports] = ["eth2"]
default[:vnet][:vna][:routes] = []

default[:vnet][:vna][:docker][:registry] = nil
#default[:vnet][:vna][:docker][:registry] = "192.168.20.101:5000"
default[:vnet][:vms] = []

# router
default[:vnet][:router][:ifconfig] = []

# lxc
default[:lxc][:basedir] = "/var/lib/lxc"
default[:lxc][:template_name] = "centos6"
