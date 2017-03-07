#!/bin/bash

set -ex -o pipefail

CID=
docker_rm() {
  if [[ -z "$CID" ]]; then
      return 0
  fi
  if [[ -n "$LEAVE_CONTAINER" ]]; then
      if [[ "${LEAVE_CONTAINER}" != "0" ]]; then
          echo "Skip to clean container: ${CID}"
          return 0
      fi
  fi
  docker rm -f "${CID}"
}
trap 'docker_rm' EXIT

BUILD_ENV_PATH=${1:?"ERROR: env file is not given."}
if [[ -n "${BUILD_ENV_PATH}" && ! -f "${BUILD_ENV_PATH}" ]]; then
  echo "ERROR: Can't find the file: ${BUILD_ENV_PATH}" >&2
  exit 1
fi

set -a
. ${BUILD_ENV_PATH}
set +a

if [[ -n "$JENKINS_HOME" ]]; then
  # openvnet-axsh/branch1/el7
  img_tag=$(echo "rpm-install.${JOB_NAME}/${BUILD_OS}" | tr '/' '.')
else
  img_tag="rpm-install.openvnet.$(git rev-parse --abbrev-ref HEAD).${BUILD_OS}"
fi

docker build \
       --build-arg BRANCH="${BRANCH}" \
       --build-arg RELEASE_SUFFIX="${RELEASE_SUFFIX}" \
       --build-arg BUILD_URL="${BUILD_URL}" \
       --build-arg ISO8601_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --build-arg LONG_SHA="${LONG_SHA}" \
       -t "${img_tag}" -f "./ci/ci.el7/rpmtest/Dockerfile" .

CID=$(docker run -d ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${img_tag}")
docker attach $CID
