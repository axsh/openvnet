#!/bin/bash

set -xe

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
repo_dir=

BUILD_TYPE="${BUILD_TYPE:-development}"
OPENVNET_SPEC_FILE="${current_dir}/packages.d/vnet/openvnet.spec"
WORK_DIR="${WORK_DIR:-/tmp/vnet-rpmbuild}"
REPO_BASE_DIR="${REPO_BASE_DIR:-/var/www/html/repos}"
RHEL_RELVER="${RHEL_RELVER:-$(rpm --eval '%{rhel}')}"

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
case $RHEL_RELVER in
  6)
    if ! rpm -q epel-release > /dev/null; then
      rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    fi
    ;;
  7)
    if ! rpm -q epel-release > /dev/null; then
      rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi
    if ! rpm -q mysql-community-release > /dev/null; then
      rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
    fi
    ;;
  *)
    echo "ERROR: Unsupported distro: $(rpm --eval '%{dist}')" >&2
    exit 1
    ;;
esac

sudo yum-builddep -y "$OPENVNET_SPEC_FILE"

#
# Prepare build directories and put the source in place.
#

if [[ ! -d "${WORK_DIR}/SOURCES" ]]; then
  mkdir -p "${WORK_DIR}/SOURCES"
fi

# Get rid up any possible dirty build directories
find ${WORK_DIR}/{SRPMS,RPMS} -name '*.rpm' -exec rm -f {} \;

export GIT_BRANCH=${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
git archive --format=tgz --prefix="openvnet/" --output="${WORK_DIR}/SOURCES/openvnet.tar.gz" ${GIT_BRANCH}

#
# Build the packages
#

export PATH="/opt/axsh/openvnet/ruby/bin:$PATH"
if [ "$BUILD_TYPE" == "stable" ]; then
  # If we're building a stable version we must make sure we checkout the correct version of the code.
  repo_dir="${REPO_BASE_DIR}/packages/rhel/${RHEL_RELVER}/vnet/${RPM_VERSION}"

  git checkout "${RPM_VERSION}"
  echo "Building the following commit for stable version ${RPM_VERSION}"
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
sudo mkdir -p "${repo_dir}"
sudo chown $USER "${repo_dir}"

cp -a ${WORK_DIR}/RPMS/* ${repo_dir}
createrepo "${repo_dir}"
