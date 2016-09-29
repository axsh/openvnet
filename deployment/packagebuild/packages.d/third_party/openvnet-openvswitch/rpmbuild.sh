#!/bin/bash
#
# dependencies: rpm-build redhat-rpm-config rpmdevtools yum-utils gcc make python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r)
#

set -e

ovs_version=${1:-"2.4.1"}

rpmdev-setuptree

rpm -q redhat-lsb > /dev/null || yum install -y redhat-lsb

cd $(rpm -E '%{_sourcedir}')
curl -O http://openvswitch.org/releases/openvswitch-${ovs_version}.tar.gz
tar zxvf openvswitch-${ovs_version}.tar.gz
cp openvswitch-${ovs_version}/rhel/openvswitch-kmod.files .

if [[ $(rpm -E '%{rhel}') -eq 6 ]]; then 
  # RHEL/CentOS6
  yum-builddep -y openvswitch-${ovs_version}/rhel/openvswitch.spec
  # Run openvswitch unit tests when you set WITH_TEST=1.
  rpmbuild -bb ${WITH_TEST:---without check} openvswitch-${ovs_version}/rhel/openvswitch.spec
  # Building kmod for RHEL <= 6.5. 
  e=$(set +e; rpmdev-vercmp 6.6 $(lsb_release -s -r) > /dev/null; echo $?;)
  if [[ $e -eq 11 ]]; then
    rpmbuild -bb openvswitch-${ovs_version}/rhel/openvswitch-kmod-rhel6.spec
  fi
else
  # RHEL/CentOS >= 7
  yum-builddep -y openvswitch-${ovs_version}/rhel/openvswitch-fedora.spec
  # Run openvswitch unit tests when you set WITH_TEST=1.
  rpmbuild -bb ${WITH_TEST:---without check} openvswitch-${ovs_version}/rhel/openvswitch-fedora.spec
fi