#!/bin/bash
#
# dependencies: rpm-build redhat-rpm-config rpmdevtools yum-utils gcc make python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r)
#

set -e

ovs_version="2.3.1"

rpmdev-setuptree

cd $(rpm -E '%{_sourcedir}')
curl -O http://openvswitch.org/releases/openvswitch-${ovs_version}.tar.gz
tar zxvf openvswitch-${ovs_version}.tar.gz
cp openvswitch-${ovs_version}/rhel/openvswitch-kmod.files .

yum-builddep -y openvswitch-${ovs_version}/rhel/openvswitch.spec
rpmbuild -bb openvswitch-${ovs_version}/rhel/openvswitch.spec
rpmbuild -bb openvswitch-${ovs_version}/rhel/openvswitch-kmod-rhel6.spec
