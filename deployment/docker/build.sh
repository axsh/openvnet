#!/bin/bash
# Run build process in docker container.

set -ex -o pipefail

SCL_RUBY="rh-ruby23"
BUILD_ENV_PATH=${1:?"ERROR: env file is not given."}

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
  img_tag=$(echo "${JOB_NAME}/${BUILD_OS}" | tr '/' '.')
  # $BUILD_CACHE_DIR/openvnet-axsh/el7/0123abcdef.tar.gz
  build_cache_base="${BUILD_OS}/${JOB_NAME%/*}"
  echo "cache_dir=${build_cache_base}" >> ${BUILD_ENV_PATH}
else
  img_tag="openvnet.x$(git rev-parse --abbrev-ref HEAD).${BUILD_OS}"
fi



/usr/bin/env

docker build \
       --build-arg SCL_RUBY="${SCL_RUBY}" \
       --build-arg BRANCH="${BRANCH}" \
       --build-arg RELEASE_SUFFIX="${RELEASE_SUFFIX}" \
       --build-arg BUILD_URL="${BUILD_URL}" \
       --build-arg ISO8601_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --build-arg LONG_SHA="${LONG_SHA}" \
       -t "${img_tag}" -f "./deployment/docker/${BUILD_OS}.Dockerfile" .


CID=$(docker run --privileged -v "/var/www/repos:/repos" -v "${BUILD_CACHE_DIR}:/cache" ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${img_tag}")
docker attach $CID

# docker cp "${CID}:${REPO_BASE_DIR}" - | $SSH_REMOTE tar xf - -C "$(dirname ${REPO_BASE_DIR})"
