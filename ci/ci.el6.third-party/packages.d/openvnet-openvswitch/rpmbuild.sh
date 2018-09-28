#!/bin/bash
#
# dependencies: rpm-build redhat-rpm-config rpmdevtools yum-utils gcc make python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r)
#

set -e

ovs_version=${1:-"2.4.1"}

rpmdev-setuptree

rpm -q redhat-lsb > /dev/null || yum install -y redhat-lsb

cd $(rpm -E '%{_sourcedir}')
wget http://openvswitch.org/releases/openvswitch-${ovs_version}.tar.gz
tar zxvf openvswitch-${ovs_version}.tar.gz

# RHEL/CentOS6
yum-builddep -y openvswitch-${ovs_version}/rhel/openvswitch.spec
# Run openvswitch unit tests when you set WITH_TEST=1.
rpmbuild -bb ${WITH_TEST:---without check} openvswitch-${ovs_version}/rhel/openvswitch.spec
