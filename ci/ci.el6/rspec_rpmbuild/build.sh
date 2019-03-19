#!/bin/bash
# Run build process in docker container.

set -ex -o pipefail

CID=
SCL_RUBY="rh-ruby23"

BUILD_ENV_PATH=${1:?"ERROR: env file is not given."}

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

if [[ -n "${BUILD_ENV_PATH}" && ! -f "${BUILD_ENV_PATH}" ]]; then
  echo "ERROR: Can't find the file: ${BUILD_ENV_PATH}" >&2
  exit 1
fi

echo "COMMIT_ID=$(git rev-parse HEAD)" >> ${BUILD_ENV_PATH}
# /tmp is memory file system on docker.
echo "WORK_DIR=/var/tmp/rpmbuild" >> ${BUILD_ENV_PATH}

# http://stackoverflow.com/questions/19331497/set-environment-variables-from-file
set -a
. ${BUILD_ENV_PATH}
set +a

if [[ -n "$JENKINS_HOME" ]]; then
  # openvnet-axsh/branch1/el7
  img_tag="openvnet/rspec-rpmbuild/el6:${BRANCH}.${RELEASE_SUFFIX}"
  # $BUILD_CACHE_DIR/openvnet-axsh/el7/0123abcdef.tar.gz
  echo "build_cache_base=el6" >> ${BUILD_ENV_PATH}
else
  img_tag="openvnet.$(git rev-parse --abbrev-ref HEAD).${BUILD_OS}"
fi

/usr/bin/env

docker build \
       --build-arg SCL_RUBY="${SCL_RUBY}" \
       --build-arg BRANCH="${BRANCH}" \
       --build-arg RELEASE_SUFFIX="${RELEASE_SUFFIX}" \
       --build-arg BUILD_URL="${BUILD_URL}" \
       --build-arg ISO8601_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --build-arg LONG_SHA="${LONG_SHA}" \
       -t "${img_tag}" -f "./ci/ci.el6/rspec_rpmbuild/Dockerfile" .


CID=$(docker run -v "${REPO_BASE_DIR}:/repos" -v "${BUILD_CACHE_DIR}:/cache" ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${img_tag}")
docker attach $CID

tar -cO --directory="${REPO_BASE_DIR}" "${BRANCH}" | $SSH_REMOTE tar -xf - -C "${REPO_BASE_DIR}"

# Set the group with write permissions so the garbage collection job can delete these later
$SSH_REMOTE /bin/bash <<EOS
chgrp -R repoci "${REPO_BASE_DIR}"
chmod -R g+w "${REPO_BASE_DIR}"
EOS
