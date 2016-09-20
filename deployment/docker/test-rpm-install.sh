#!/bin/bash

set -ex -o pipefail

CID=
docker_rm() {
  if [[ -z "${CID}" ]]; then
    return 0
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
  img_tag="rpm-install.${JOB_NAME}/${BUILD_OS}"
else
  img_tag="rpm-install.openvnet/$(git rev-parse --abbrev-ref HEAD)/${BUILD_OS}"
fi

docker build -t "${img_tag}" -f "./deployment/docker/${BUILD_OS}-rpm-test.Dockerfile" .
CID=$(docker run -d ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} "${img_tag}")
docker exec -t $CID /bin/sh -c "echo '172.17.0.1 devrepo' >> /etc/hosts"
docker exec -t $CID /bin/sh -c "echo '${RELEASE_SUFFIX}' > /etc/yum/vars/ovn_release_suffix"
docker exec $CID yum install -y openvnet
