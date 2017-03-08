#!/bin/bash

openvnet/ci/ci.el7/integration_test/multibox/build.sh

. /etc/profile.d/rvm.sh

rvm use 2.2.0
gem install bundler
cd openvnet/integration_test
bundle install

set -xe

RELEASE_VERSION="el7" bin/itest-spec run
