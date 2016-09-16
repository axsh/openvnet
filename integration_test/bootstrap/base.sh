#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

LOG_FILE=base.sh.LOG
touch ${LOG_FILE}

# Do some changes ...

vnet_root=/opt/axsh/openvnet
PATH=${vnet_root}/ruby/bin:${PATH}
vnmgr=172.16.9.10

## 'yum' the openvnet.repo & openvnet-third-party.repo files
echo "curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet.repo" >> ${LOG_FILE}

curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet.repo

# third-party
echo "curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet-third-party.repo" >> ${LOG_FILE}

curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet-third-party.repo

##

#cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
#DEVICE=eth1
#DEVICETYPE=ovs
#TYPE=OVSPort
#OVS_BRIDGE=br0
#BOOTPROTO=none
#ONBOOT=yes
#HOTPLUG=no
#EOF

#rpm -Uvh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release || :

echo "yum -y install epel-release" >> ${LOG_FILE}
yum -y install epel-release

## Openvnet
echo "yum -y install openvnet" >> ${LOG_FILE}
######  Does not work! (Yet!) For now -- skip it and come back later.
######  yum -y install openvnet

### lxc install, add instances
echo "yum -y install lxc lxc-templates" >> ${LOG_FILE}
yum -y install lxc lxc-templates

echo "lxc-create -t centos -n inst1" >> ${LOG_FILE}
lxc-create -t centos -n inst1

echo "lxc-create -t centos -n inst2" >> ${LOG_FILE}
lxc-create -t centos -n inst2

#cat > /etc/openvnet/common.conf <<EOF
#registry {
#  adapter "redis"
#  host "${vnmgr}"
#  port 6379
#}
#db {
#  adapter "mysql2"
#  host "localhost"
#  database "vnet"
#  port 3306
##  user "root"
#  password ""
#}
#EOF

echo 1 > /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv4/ip_forward

iptables --flush
iptables -L
service iptables stop
chkconfig iptables off
