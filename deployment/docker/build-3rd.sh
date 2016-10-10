#!/bin/bash
# Run build process in docker container.

set -ex -o pipefail

CID=
TMPDIR=$(mktemp -d)
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

trap "docker_rm; rm -rf ${TMPDIR}" EXIT

function docker_cp() {
  local cid=${2%:*}
  if [[ -z $cid ]]; then
    # container -> host
    docker cp $1 $2
  else
    # host -> container. Docker 1.7 or earlier does not support.
    docker cp $1 $2 || {
      local path=${2#*:}
      tar -cO $1 | docker exec -i "${cid}" bash -c "tar -xf - -C ${path}"
    }
  fi
}

img_tag="3rd-build."
if [[ -n "$JENKINS_HOME" ]]; then
  # openvnet-axsh/branch1/el7
  img_tag="${img_tag}${JOB_NAME}/${BUILD_OS}"
else
  img_tag="${img_tag}openvnet/$(git rev-parse --abbrev-ref HEAD)/${BUILD_OS}"
fi

docker build -t "${img_tag}" -f "./deployment/docker/${BUILD_OS}-3rd-build.Dockerfile" .
CID=$(docker run ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${img_tag}")
# Upload checked out tree to the container.
docker_cp . "${CID}:/var/tmp/openvnet"
# Run build script
docker exec -t "${CID}" /bin/bash -c "cd openvnet/deployment/packagebuild; ./build_packages_third_party.sh"
# Pull compiled yum repository
docker cp "${CID}:${REPO_BASE_DIR}" - | $SSH_REMOTE tar xf - -C "$(dirname ${REPO_BASE_DIR})"
