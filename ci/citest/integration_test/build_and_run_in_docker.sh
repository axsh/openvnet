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
CACHE_DIR="/data/openvnet-ci/branches"

repo_and_tag="openvnet/integration-test:${BRANCH}.${RELEASE_SUFFIX}"

function cleanup() {
  if [[ -z "${LEAVE_CONTAINER}" || "${LEAVE_CONTAINER}" == "0" ]]; then
    # Clean up containers
    # Images don't need to be cleaned up. Removing them immediately would slow down
    # builds and they can be garbage collected later.
    for CID in $(sudo docker ps -af ancestor="${repo_and_tag}" --format "{{.ID}}"); do
      sudo docker rm -f "${CID}"
    done
  else
    echo "LEAVE_CONTAINER was set and not 0. Skip container cleanup."
  fi
}

# trap "cleanup" EXIT

sudo docker build -t "${repo_and_tag}" \
     --build-arg BRANCH="${BRANCH}" \
     --build-arg RELEASE_SUFFIX="${RELEASE_SUFFIX}" \
     --build-arg REBUILD="${REBUILD}" -f "./ci/citest/integration_test/Dockerfile" .

CID=$(sudo docker run --privileged -v "${DATA_DIR}":/data -d "${repo_and_tag}")
docker attach $CID
