#!/bin/bash
# Run build process in docker container.

set -ex -o pipefail

CID=
function docker_rm() {
    if [[ -z "$CID" ]]; then
        return 0
    fi
    if [[ -n "$LEAVE_CONTAINER" ]]; then
        if [[ "${LEAVE_CONTAINER}" != "0" ]]; then
            echo "Skip to clean container: ${CID}"
            return 0
        fi
    fi
    docker rm -f "$CID" 
}

trap "docker_rm" EXIT

BUILD_ENV_PATH=${1:?"ERROR: env file is not given."}

if [[ -n "${BUILD_ENV_PATH}" && ! -f "${BUILD_ENV_PATH}" ]]; then
  echo "ERROR: Can't find the file: ${BUILD_ENV_PATH}" >&2
  exit 1
fi

set -a
. ${BUILD_ENV_PATH}
set +a

img_tag="openvnet/${BRANCH_NAME}"
docker build -t "${img_tag}" - < "./deployment/docker/el7.Dockerfile"
CID=$(docker run ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${img_tag}")
docker cp . "${CID}:/var/tmp/openvnet"
docker exec -t "${CID}" /bin/bash -c "cd openvnet; ./deployment/packagebuild/build_packages_vnet.sh"
