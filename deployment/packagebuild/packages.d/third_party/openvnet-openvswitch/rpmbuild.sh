#!/bin/bash
#
# dependencies: rpm-build redhat-rpm-config rpmdevtools yum-utils gcc make python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r)
#

set -e

ovs_version="1.10.0"

work_dir=${WORK_DIR:-/tmp/vnet-rpmbuild}
package_work_dir=${work_dir}/packages.d/third_party/openvnet-openvswitch
possible_archs="i386 noarch x86_64"

rpmdev-setuptree

tmpdir=$(mktemp -d)
cd ${tmpdir}

curl -O http://openvswitch.org/releases/openvswitch-${ovs_version}.tar.gz
cp openvswitch-${ovs_version}.tar.gz ~/rpmbuild/SOURCES/
tar zxvf openvswitch-${ovs_version}.tar.gz
cp openvswitch-${ovs_version}/rhel/openvswitch-kmod.files ~/rpmbuild/SOURCES

rpmbuild -bb openvswitch-${ovs_version}/rhel/openvswitch.spec
rpmbuild -bb openvswitch-${ovs_version}/rhel/openvswitch-kmod-rhel6.spec

for i in ${possible_archs}; do
  mkdir -p ${package_work_dir}/pkg/${i}
  cp ~/rpmbuild/RPMS/${i}/openvswitch-${ovs_version}*.rpm ${package_work_dir}/pkg/ | :
  cp ~/rpmbuild/RPMS/${i}/kmod-openvswitch-${ovs_version}*.rpm ${package_work_dir}/pkg/ | :
done

rm -rf ${tmpdir}

# clean up rpmbuild direcotry 
#rpmdev-wipetree || {
#  # root will fail to exec rpmdev-wipetree
#  rm -rf ~/rpmbuild
#}
