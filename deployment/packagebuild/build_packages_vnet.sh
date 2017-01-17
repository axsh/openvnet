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

function yum_check_install() {
  for i in $*; do
    if ! rpm -q $i &> /dev/null; then
      echo $i
    fi
  done | xargs --no-run-if-empty yum install -y
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

yum_check_install yum-utils createrepo rpmdevtools
yum_check_install centos-release-scl scl-utils

if [[ -n "${SCL_RUBY}" ]]; then
  # Try install devel package with the $SCL_RUBY version if specified.
  yum_check_install "${SCL_RUBY}-ruby-devel"
fi
if [[ $(rpm --eval '%{defined scl_ruby}') -eq 0 ]]; then
  # Respect pre-installed rh-rubyXX or rubyXXX.
  echo "FATAL: No SCL Ruby found. Please install any of rh-rubyXX from Software Collections." 1>&2
  exit 1
fi
SCL_RUBY=$(rpm --eval '%{scl_ruby}')
# Make sure that we work with the correct version of openvnet-ruby
sudo cp "${current_dir}/../yum_repositories/${BUILD_TYPE}/openvnet-third-party.repo" /etc/yum.repos.d

sudo yum-builddep -y "$OPENVNET_SPEC_FILE"

#
# Prepare build directories and put the source in place.
#

# scl_source is designed to run in the context +e. Otherwise
# non-zero exit from scl_enabled causes the program terminate.
set +e
. scl_source enable ${SCL_RUBY}
set -e

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
export PATH="/opt/axsh/openvnet/ruby/bin:$PATH"

repo_rel_path="packages/rhel/${RHEL_RELVER}/vnet/${RELEASE_SUFFIX}"
if [ "$BUILD_TYPE" == "stable" ]; then
  # If we're building a stable version we must make sure we checkout the correct version of the code.
  repo_dir="${REPO_BASE_DIR}/packages/rhel/${RHEL_RELVER}/vnet/${RPM_VERSION}"

  git checkout "${RELEASE_SUFFIX}"
  echo "Building the following commit for stable version ${RELEASE_SUFFIX}"
  git log -n 1 --format=short

  rpmbuild -ba --define "_topdir ${WORK_DIR}" "${OPENVNET_SPEC_FILE}"
else
  # If we're building a development version we set the git commit time and hash as release
  timestamp=$(date --date="$(git show -s --format=%cd --date=iso HEAD)" +%Y%m%d%H%M%S)
  RELEASE_SUFFIX="${timestamp}git$(git rev-parse --short HEAD)"

  repo_dir="${REPO_BASE_DIR}/packages/rhel/${RHEL_RELVER}/vnet/${RELEASE_SUFFIX}"

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
