#!/bin/bash

set -e

rubyver=${1:-"2.3.1"}

yum install -y rpmdevtools rpm-build yum-utils
yum-builddep -y openvnet-ruby.spec
rpmdev-setuptree
spectool -g --sourcedir -d "build_rubyver ${rubyver}" openvnet-ruby.spec
rpmbuild -bb -D "build_rubyver ${rubyver}" openvnet-ruby.spec