#!/bin/bash

set -xe

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
repo_dir=

BUILD_TYPE="${BUILD_TYPE:-development}"
OPENVNET_SPEC_FILE="${current_dir}/packages.d/vnet/openvnet.spec"
OPENVNET_SRC_ROOT_DIR="$( cd "${current_dir}/../.."; pwd )"
WORK_DIR="${WORK_DIR:-/tmp/vnet-rpmbuild}"
REPO_BASE_DIR="${REPO_BASE_DIR:-/var/www/html/repos}"
POSSIBLE_ARCHS=( 'x86_64' 'i386' 'noarch' )

function check_dependency() {
  local cmd="$1"
  local pkg="$2"

  command -v ${cmd} >/dev/null 2>&1 || {
    sudo yum install -y ${pkg}
  }
}

if [ "${BUILD_TYPE}" == "stable" ] && [ -z "${RPM_VERSION}" ]; then
  echo "You need to set RPM_VERSION when building a stable version. This should contain the name of a branch of tag for git to checkout.
        Ex: v0.7"
  exit 1
fi

#
# Install dependencies
#

check_dependency yum-builddep yum-utils
check_dependency createrepo createrepo

# Make sure that we work with the correct version of openvnet-ruby
sudo cp "${current_dir}/../yum_repositories/${BUILD_TYPE}/openvnet-third-party.repo" /etc/yum.repos.d

sudo yum-builddep -y "$OPENVNET_SPEC_FILE"

#
# Prepare build directories and put the source in place.
#

OPENVNET_SRC_BUILD_DIR="${WORK_DIR}/SOURCES/openvnet"
if [ -d "$OPENVNET_SRC_BUILD_DIR" ]; then
  rm -rf "$OPENVNET_SRC_BUILD_DIR"
fi

mkdir -p "${WORK_DIR}/SOURCES"
cp -r "$OPENVNET_SRC_ROOT_DIR" "${WORK_DIR}/SOURCES/openvnet"

# Get rid up any possible dirty build directories
for arch in "${POSSIBLE_ARCHS[@]}"; do
  if [ -d "${WORK_DIR}/RPMS/${arch}" ]; then
    rm -rf "${WORK_DIR}/RPMS/${arch}"
  fi
done


# Clean up the source dir if it's dirty
cd ${OPENVNET_SRC_BUILD_DIR}
git reset --hard
git clean -xdf

#
# Build the packages
#

if [ "$BUILD_TYPE" == "stable" ]; then
  # If we're building a stable version we must make sure we checkout the correct version of the code.
  repo_dir="${REPO_BASE_DIR}/packages/rhel/6/vnet/${RPM_VERSION}"

  git checkout "${RPM_VERSION}"
  echo "Building the following commit for stable version ${RPM_VERSION}"
  git log -n 1 --format=short

  rpmbuild -ba --define "_topdir ${WORK_DIR}" "${OPENVNET_SPEC_FILE}"
else
  # If we're building a development version we set the git commit time and hash as release
  timestamp=$(date --date="$(git show -s --format=%cd --date=iso HEAD)" +%Y%m%d%H%M%S)
  RELEASE_SUFFIX="${timestamp}git$(git rev-parse --short HEAD)"

  repo_dir="${REPO_BASE_DIR}/packages/rhel/6/vnet/${RELEASE_SUFFIX}"

  rpmbuild -ba --define "_topdir ${WORK_DIR}" --define "dev_release_suffix ${RELEASE_SUFFIX}" "${OPENVNET_SPEC_FILE}"
fi


#
# Prepare the yum repo
#
for arch in "${POSSIBLE_ARCHS[@]}"; do
  if [ -d "${repo_dir}/${arch}" ]; then
    rm -rf "${repo_dir}/${arch}"
  fi
done
sudo mkdir -p "${repo_dir}"
sudo chown $USER "${repo_dir}"

for arch in "${POSSIBLE_ARCHS[@]}"; do
  if [ -d "${WORK_DIR}/RPMS/${arch}" ]; then
    mv "${WORK_DIR}/RPMS/${arch}" "${repo_dir}/${arch}"
  fi
done

createrepo "${repo_dir}"

current_symlink="${REPO_BASE_DIR}/packages/rhel/6/vnet/current"
if [ -L "${current_symlink}" ]; then
  sudo rm "${current_symlink}"
fi
sudo ln -s "${repo_dir}" "${current_symlink}"
