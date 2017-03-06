#!/bin/bash


cat <<EOF > openvnet/ci/citest/integration_test/multibox/base/guestroot/etc/yum.repos.d/
[openvnet]
name=OpenVNet
failovermethod=priority
baseurl=https://ci.openvnet.org/repos/${BRANCH}/packages/rhel/${BUILD_OS#*el}/vnet/${RELEASE_SUFFIX:-current}
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

RELEASE_VERSION="${BUILD_OS}" bin/itest-spec run
