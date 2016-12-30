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

echo "export PATH=/opt/axsh/openvnet/ruby/bin:$PATH" >> $HOME/.bashrc

## 'yum' the openvnet.repo & openvnet-third-party.repo files
echo "curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet.repo" >> ${LOG_FILE}

curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet.repo

# third-party
echo "curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet-third-party.repo" >> ${LOG_FILE}

curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet-third-party.repo

##

echo "yum -y install epel-release" >> ${LOG_FILE}
yum -y install epel-release

## Openvnet
echo "yum -y install openvnet" >> ${LOG_FILE}
yum -y install openvnet

# Brctl
#echo "yum -y install bridge-utils" >> ${LOG_FILE}
#yum -y install bridge-utils

# Setup cgroup for lxc use
mkdir /cgroup
echo "cgroup /cgroup cgroup defaults 0 0" >> /etc/fstab
mount /cgroup

### lxc install, add instances
echo "yum -y install lxc lxc-templates" >> ${LOG_FILE}
yum -y install lxc lxc-templates

# create base to get the tarball then destroy it

echo "lxc-create -t centos base" >> ${LOG_FILE}
lxc-create -t centos -n base

echo "lxc-destroy -n base" >> ${LOG_FILE}
lxc-destroy -n base


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

###+
#   These lines come from the cleanup.sh that comes with
# a typical packer installation/template. They are needed
# to be able to use packer-generated .ovf files as input/sources
# back in to packer. Otherwise, ssh fails!
###-
/bin/rm -f /etc/udev/rules.d/70-persistent-net.rules
mkdir -p /etc/udev/rules.d/70-persistent-net.rules
/bin/rm -f /lib/udev/rules.d/75-persistent-net-generator.rules
/bin/rm -rf /dev/.udev/


