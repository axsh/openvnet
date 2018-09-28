#!/bin/bash
#
# dependencies: rpm-build redhat-rpm-config rpmdevtools yum-utils gcc make
#

set -e

rpmdev-setuptree

cp "$(dirname ${BASH_SOURCE[0]})/openvnet-zeromq4.spec" "$(rpm -E '%{_rootdir}')/SPECS/"

cd $(rpm -E '%{_rootdir}')

spectool -g -R SPECS/zeromq4.spec
yum-builddep -y SPECS/zeromq4.spec

rpmbuild -bp SPECS/zeromq4.spec 
QA_RPATHS=0001 rpmbuild -bb SPECS/zeromq4.spec 
