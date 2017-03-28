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

set -a
. ${1}
set +a


if [[ -n "$JENKINS_HOME" ]]; then
  img_tag="openvnet/3rd-party:${RELEASE_SUFFIX}.${BRANCH}"
else
  img_tag="openvnet.$(git rev-parse --abbrev-ref HEAD).el6"
fi


docker build \
       --build-arg BRANCH="${BRANCH}" \
       --build-arg RELEASE_SUFFIX="${RELEASE_SUFFIX}" \
       --build-arg BUILD_URL="${BUILD_URL}" \
       --build-arg ISO8601_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --build-arg LONG_SHA="${LONG_SHA}" \
       -t "${img_tag}" -f "./ci/ci.el6.third-party/Dockerfile" .

CID=$(docker run -v "/var/www/html/repos:/repos" ${1:+--env-file $1} -d "${img_tag}")
docker attach $CID

# tar -cO --directory="${REPO_BASE_DIR}" "${BRANCH}" | $SSH_REMOTE tar -xf - -C "${REPO_BASE_DIR}"
