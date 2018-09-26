#!/bin/bash

set -ex -o pipefail

whereami="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"

BUILD_ENV_PATH=${1:?"ERROR: env file is not given."}
if [[ -n "${BUILD_ENV_PATH}" && ! -f "${BUILD_ENV_PATH}" ]]; then
  echo "ERROR: Can't find the file: ${BUILD_ENV_PATH}" >&2
  exit 1
fi

set -a
. ${BUILD_ENV_PATH}
set +a

DATA_DIR="${DATA_DIR:-/data}"
CACHE_DIR="/data/openvnet-ci/el6/branches"
BOXES_SCL_RUBY="rh-ruby23"

repo_and_tag="openvnet/integration-test/el6:${BRANCH}.${RELEASE_SUFFIX}"

function cleanup () {
    [[ -z "${CID}" ]] && return 0
    [[ -z "${LEAVE_CONTAINER}" || "${LEAVE_CONTAINER}" == "0" ]] && {
        sudo docker rm -f "${CID}"
    } || { echo "Skip container cleanup for: ${CID}" ; }

    local user=$(/usr/bin/id -run)
    sudo chown -R $user:$user "${CACHE_DIR}"/"${BRANCH}"
}

trap "cleanup" EXIT

echo "COMMIT_ID=$(git rev-parse HEAD)" >> ${BUILD_ENV_PATH}

sudo docker build -t "${repo_and_tag}" \
     --build-arg BRANCH="${BRANCH}" \
     --build-arg RELEASE_SUFFIX="${RELEASE_SUFFIX}" \
     --build-arg BUILD_OS="${BUILD_OS}" \
     --build-arg REBUILD="${REBUILD}" \
     --build-arg BOXES_SCL_RUBY="${BOXES_SCL_RUBY}" \
     -f "./ci/ci.el6/integration_test/Dockerfile" .

CID=$(sudo docker run --privileged -v "${DATA_DIR}":/data ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${repo_and_tag}")
sudo docker attach $CID
