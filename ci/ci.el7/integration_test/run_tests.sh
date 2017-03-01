#!/bin/bash

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

${current_dir}/multibox/build.sh

. ${current_dir}/../../cache_functions.sh "openvnet-ci/branches/${BRANCH}"
. /etc/profile.d/rvm.sh


try_load_cache "/data" "/data" "${COMMIT_ID}"

rvm use 2.2.0
gem install bundler
cd integration_test
bundle install

create_cache "/data" "/data" "${COMMIT_ID}" "${current_dir}/build-cache.list"

set -xe

RELEASE_VERSION="el7" bin/itest-spec run
