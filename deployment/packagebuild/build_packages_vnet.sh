#!/bin/bash

set -xe

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

BUILD_TYPE="${BUILD_TYPE:-development}"
OPENVNET_SPEC_FILE="${current_dir}/packages.d/vnet/openvnet.spec"
OPENVNET_SRC_ROOT_DIR="$( cd "${current_dir}/../.."; pwd )"
WORK_DIR="${WORK_DIR:-/tmp/vnet-rpmbuild}"
REPO_BASE_DIR="${REPO_BASE_DIR:-/var/www/html/repos}"
POSSIBLE_ARCHS=( 'x86_64' 'i386' 'noarch' )
RHEL_RELVER="${RHEL_RELVER:-$(rpm --eval '%{rhel}')}"

function check_dependency() {
  local cmd="$1"
  local pkg="$2"

  command -v ${cmd} >/dev/null 2>&1 || {
    sudo yum install -y ${pkg}
  }
}

if [ "${BUILD_TYPE}" == "stable" ] && [ -z "${RELEASE_SUFFIX}" ]; then
  echo "You need to set RELEASE_SUFFIX when building a stable version. This should contain the name of a branch of tag for git to checkout.
        Ex: v0.7"
  exit 1
elif [[ -z "${RELEASE_SUFFIX}" ]]; then
  # RELEASE_SUFFIX is recommended to pass to this script. The line is for
  # the backward compatibility to the current CI infrastructure.
  RELEASE_SUFFIX=$(${current_dir}/gen-dev-build-tag.sh)
fi

#
# Install dependencies
#

check_dependency yum-builddep yum-utils
check_dependency createrepo createrepo

if ! yum repolist --noplugins --cacheonly enabled | grep openvnet-third-party > /dev/null; then
  # Make sure that we work with the correct version of openvnet-ruby
  sudo cp "${current_dir}/../yum_repositories/${BUILD_TYPE}/openvnet-third-party.repo" /etc/yum.repos.d
fi

sudo yum-builddep -y "$OPENVNET_SPEC_FILE"

#
# Prepare build directories and put the source in place.
#

OPENVNET_SRC_BUILD_DIR="${WORK_DIR}/SOURCES/openvnet"
if [[ -d "$OPENVNET_SRC_BUILD_DIR" && -z "${SKIP_CLEANUP}" ]]; then
  rm -rf "$OPENVNET_SRC_BUILD_DIR"
fi

mkdir -p "${OPENVNET_SRC_BUILD_DIR}"
# Copy only the tracked files to rpmbuild SOURCES/.
(
  cd $(git rev-parse --show-toplevel)
  git archive HEAD | tar x -C "${OPENVNET_SRC_BUILD_DIR}"
)

#
# Build the packages
#

repo_rel_path="packages/rhel/${RHEL_RELVER}/vnet/${RELEASE_SUFFIX}"
if [ "$BUILD_TYPE" == "stable" ]; then
  # If we're building a stable version we must make sure we checkout the correct version of the code.

  git checkout "${RELEASE_SUFFIX}"
  echo "Building the following commit for stable version ${RELEASE_SUFFIX}"
  git log -n 1 --format=short

  rpmbuild -ba --define "_topdir ${WORK_DIR}" "${OPENVNET_SPEC_FILE}"
else
  # If we're building a development version we set the git commit time and hash as release

  rpmbuild -ba --define "_topdir ${WORK_DIR}" --define "dev_release_suffix ${RELEASE_SUFFIX}" "${OPENVNET_SPEC_FILE}"
fi

#
# Prepare the yum repo
#
repo_dir="${REPO_BASE_DIR}/${repo_rel_path}"
for arch in "${POSSIBLE_ARCHS[@]}"; do
  if [ -d "${repo_dir}/${arch}" ]; then
    rm -rf "${repo_dir}/${arch}"
  fi
done
sudo mkdir -p "${repo_dir}"
if [[ -n "$USER" ]]; then
    sudo chown $USER "${repo_dir}"
fi

for arch in "${POSSIBLE_ARCHS[@]}"; do
  if [ -d "${WORK_DIR}/RPMS/${arch}" ]; then
    mv "${WORK_DIR}/RPMS/${arch}" "${repo_dir}/${arch}"
  fi
done

createrepo "${repo_dir}"

current_symlink="$(dirname ${repo_dir})/current"
if [ -L "${current_symlink}" ]; then
  sudo rm "${current_symlink}"
fi
sudo ln -s "./$(basename ${repo_dir})" "${current_symlink}"
