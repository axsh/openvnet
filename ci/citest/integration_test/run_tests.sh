#!/bin/bash


cat <<EOF > openvnet/ci/citest/integration_test/multibox/base/guestroot/etc/yum.repos.d/
[openvnet]
name=OpenVNet
failovermethod=priority
baseurl=https://ci.openvnet.org/repos/${BRANCH}/packages/rhel/7/vnet/${RELEASE_SUFFIX}
enabled=1
gpgcheck=0
EOF

openvnet/ci/citest/integration_test/multibox/build.sh

. /etc/profile.d/rvm.sh

rvm use 2.2.0
gem install bundler
cd openvnet/integration_test
bundle install

set -xe

bin/itest-spec run simple_nw
