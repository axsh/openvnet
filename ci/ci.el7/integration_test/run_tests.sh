#!/bin/bash

openvnet/ci/ci.el7/integration_test/multibox/build.sh

. ci/ci.el7/cache_functions.sh "openvnet-ci/branches/${BRANCH}"
. /etc/profile.d/rvm.sh

try_load_cache "/data" "/data" "${COMMIT_ID}"

rvm use 2.2.0
gem install bundler
cd openvnet/integration_test
bundle install
create_cache "/data" "/data" "${COMMIT_ID}" "openvnet/ci/ci.el7/integration_test/build-cache.list"
set -xe

RELEASE_VERSION="el7" bin/itest-spec run
