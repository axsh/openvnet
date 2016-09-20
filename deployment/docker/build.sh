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
  img_tag="${JOB_NAME}/${BUILD_OS}"
  # $BUILD_CACHE_DIR/openvnet-axsh/el7/0123abcdef.tar.gz
  build_cache_base="${BUILD_CACHE_DIR}/${BUILD_OS}/${JOB_NAME%/*}"
else
  img_tag="openvnet/$(git rev-parse --abbrev-ref HEAD)/${BUILD_OS}"
  build_cache_base="${BUILD_CACHE_DIR}"
fi

/usr/bin/env
docker build -t "${img_tag}" -f "./deployment/docker/${BUILD_OS}.Dockerfile" .
CID=$(docker run ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${img_tag}")
# Upload checked out tree to the container.
docker cp . "${CID}:/var/tmp/openvnet"
# Upload build cache if found.
if [[ -n "$BUILD_CACHE_DIR" && -d "${build_cache_base}" ]]; then
  for f in $(ls ${build_cache_base}); do
    cached_commit=$(basename $f)
    cached_commit="${cached_commit%.*}"
    if git rev-list "${COMMIT_ID}" | grep "${cached_commit}" > /dev/null; then
      echo "FOUND build cache ref ID: ${cached_commit}"
      cat "${build_cache_base}/$f" | docker cp - "${CID}:/"
      break;
    fi
  done
fi
# Run build script
docker exec -t "${CID}" /bin/bash -c "cd openvnet; SKIP_CLEANUP=1 ./deployment/packagebuild/build_packages_vnet.sh"
if [[ -n "$BUILD_CACHE_DIR" ]]; then
    if [[ ! -d "$BUILD_CACHE_DIR" || ! -w "$BUILD_CACHE_DIR" ]]; then
        echo "ERROR: BUILD_CACHE_DIR '${BUILD_CACHE_DIR}' does not exist or not writable." >&2
        exit 1
    fi
    if [[ ! -d "${build_cache_base}" ]]; then
      mkdir -p "${build_cache_base}"
    fi
    docker cp './deployment/docker/build-cache.list' "${CID}:/var/tmp/build-cache.list"
    docker exec "${CID}" tar cO --directory=/ --files-from=/var/tmp/build-cache.list > "${build_cache_base}/${COMMIT_ID}.tar"
    # Clear build cache files which no longer referenced from Git ref names (branch, tags)
    git show-ref --head --dereference | awk '{print $1}' > "${TMPDIR}/sha.a"
    (cd "${build_cache_base}"; ls *.tar) | cut -d '.' -f1 > "${TMPDIR}/sha.b"
    # Set operation: B - A
    join -v 2 <(sort -u ${TMPDIR}/sha.a) <(sort -u ${TMPDIR}/sha.b) | while read i; do
      echo "Removing build cache: ${build_cache_base}/${i}.tar"
      rm -f "${build_cache_base}/${i}.tar" || :
    done
fi
# Pull compiled yum repository
docker cp "${CID}:${REPO_BASE_DIR}" "$(dirname ${REPO_BASE_DIR})"