override[:ntp][:servers] = %w(ntp.nict.jp, ntp.jst.mfeed.ad.jp)

default[:vnet_common][:vnet_path] = "/opt/axsh/openvnet"

default["vnet_common"]["openvnet_third_party_repository_url"] = "http://192.168.2.51/repos/packages/rhel/6/third_party/current/"

default["vnet_common"]["packages"] = %w(
vim-enhanced
tcpdump
telnet
nc
bind-utils
zeromq-devel
libpcap-devel
sqlite-devel
)

default["vnet_common"]["ruby_versions"] = %w(2.0.0-p353 2.1.1)
default["vnet_common"]["ruby_global"] = "2.0.0-p353"

default["vnet_common"]["management_network"]["ipaddr"] = nil
default["vnet_common"]["management_network"]["mask"] = "255.255.255.0"
default["vnet_common"]["management_network"]["gateway"] = nil

default["vnet_common"]["config"]["registry_host"] = "127.0.0.1"
default["vnet_common"]["config"]["registry_port"] = 6379
default["vnet_common"]["config"]["db_host"] = "localhost"
default["vnet_common"]["config"]["db_port"] = 3306
