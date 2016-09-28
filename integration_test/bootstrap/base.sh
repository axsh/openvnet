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
yum -y install openvnet

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

### Test line -- this might be bad!
# But... I am unable to successfully use packer to build
# a machine using as input a machine created previously by 
# packer: packer is unable to ssh into the machine being 
# created, so no provisioning can be carried out. As a result,
# the 70-persistent-net.rules file is the same for the
# original (input) machine and the newly-create machine.
# This file defines the machine mac address and so two machines
# share the same address. (Logging in to the new machine will
# show that eth0 is not there - eth1 is instead!) Removing this
# file during provisioning of the _original_ machine gets
# around this.

/bin/rm /etc/udev/rules.d/70-persistent-net.rules
