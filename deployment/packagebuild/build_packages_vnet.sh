#!/bin/bash

#Upload build cache if found.

if [[ -n "${BUILD_CACHE_DIR}" ]]; then
  if [[ -n "${build_cache_base}" ]]; then
    CACHE_VOLUME="${CACHE_VOLUME}/${build_cache_base}"
  fi

  for f in $(ls "${CACHE_VOLUME}"); do
    cached_commit=$(basename $f)
    cached_commit="${cached_commit%.*}"

    if git rev-list "${COMMIT_ID}" | grep "${cached_commit}" > /dev/null; then
       echo "FOUND build cache ref ID: ${cached_commit}"
       tar -xf "${CACHE_VOLUME}/$f" -C "/"
       break
    fi
  done
fi

set -xe

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

BUILD_TYPE="${BUILD_TYPE:-development}"
OPENVNET_SPEC_FILE="${current_dir}/packages.d/vnet/openvnet.spec"
OPENVNET_SRC_ROOT_DIR="$( cd "${current_dir}/../.."; pwd )"
WORK_DIR="${WORK_DIR:-/tmp/vnet-rpmbuild}"
POSSIBLE_ARCHS=( 'x86_64' 'i386' 'noarch' )
RHEL_RELVER="${RHEL_RELVER:-$(rpm --eval '%{rhel}')}"

CACHE_VOLUME="/cache"
REPOS_VOLUME="/repos"

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

/usr/bin/mysqld_safe &

yum_check_install yum-utils createrepo rpmdevtools
yum_check_install centos-release-scl scl-utils

if [[ -n "${SCL_RUBY}" ]]; then
  # Try install devel package with the $SCL_RUBY version if specified.
  yum_check_install "${SCL_RUBY}-scldevel"
fi
if [[ $(rpm --eval '%{defined scl_ruby}') -eq 0 ]]; then
  # Respect pre-installed rh-rubyXX or rubyXXX.
  echo "FATAL: No SCL Ruby found. Please install any of rh-rubyXX from Software Collections." 1>&2
  exit 1
fi
SCL_RUBY=$(rpm --eval '%{scl_ruby}')

# CI Docker container maintains third party repo by itself. This check
# is for the manual build.
if ! (yum repolist enabled | grep openvnet-third-party) > /dev/null; then
  # Make sure that we work with the correct version of openvnet-ruby
  sudo cp "${current_dir}/../yum_repositories/${BUILD_TYPE}/openvnet-third-party.repo" /etc/yum.repos.d
fi

# Workaround for the error:
#  "failure: repodata/repomd.xml from centos-sclo-rh-source: [Errno 256] No more mirrors to try."
curl -O https://raw.githubusercontent.com/rpm-software-management/yum-utils/master/yum-builddep.py
sudo python ./yum-builddep.py -y "$OPENVNET_SPEC_FILE"

#
# Prepare build directories and put the source in place.
#

# scl_source is designed to run in the context +e. Otherwise
# non-zero exit from scl_enabled causes the program terminate.
set +e
. scl_source enable ${SCL_RUBY}
set -e

#
# Run rspec
#

(
    cd vnet
    mysqladmin -uroot create vnet_test
    bundle install --path vendor/bundle --standalone
    bundle exec rake test:db:reset
    bundle exec rspec spec
)

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

repo_rel_path="${BRANCH}/packages/rhel/${RHEL_RELVER}/vnet/${RELEASE_SUFFIX}"
if [ "$BUILD_TYPE" == "stable" ]; then
  # If we're building a stable version we must make sure we checkout the correct version of the code.
  repo_dir="${REPOS_VOLUME}/${BRANCH}/packages/rhel/${RHEL_RELVER}/vnet/${RPM_VERSION}"

  git checkout "${RELEASE_SUFFIX}"
  echo "Building the following commit for stable version ${RELEASE_SUFFIX}"
  git log -n 1 --format=short

  rpmbuild -ba --define "_topdir ${WORK_DIR}" "${OPENVNET_SPEC_FILE}"
else
  # If we're building a development version we set the git commit time and hash as release
  timestamp=$(date --date="$(git show -s --format=%cd --date=iso HEAD)" +%Y%m%d%H%M%S)
  RELEASE_SUFFIX="${timestamp}git$(git rev-parse --short HEAD)"

  repo_dir="${REPOS_VOLUME}/${BRANCH}/packages/rhel/${RHEL_RELVER}/vnet/${RELEASE_SUFFIX}"

  rpmbuild -ba --define "_topdir ${WORK_DIR}" ${STRIP_VENDOR:+--define "strip_vendor ${STRIP_VENDOR}"} --define "dev_release_suffix ${RELEASE_SUFFIX}" "${OPENVNET_SPEC_FILE}"
fi

#
# Prepare the yum repo
#
repo_dir="${REPOS_VOLUME}/${repo_rel_path}"
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


TMPDIR=$(mktemp -d)


if [[ -n "${BUILD_CACHE_DIR}" ]]; then
  if [[ ! -w /cache ]]; then
      echo "ERROR: CACHE_VOLUME '${BUILD_CACHE_DIR}' is not writable." >&2
      exit 1
  fi

  if [[ ! -d "${CACHE_VOLUME}" ]]; then
      mkdir -p "${CACHE_VOLUME}"
  fi

  tar cO --directory=/ --files-from=deployment/docker/build-cache.list > "${CACHE_VOLUME}/${COMMIT_ID}.tar"

  # Clear build cache files which no longer referenced from Git ref names (branch, tags)
  git show-ref --head --dereference | awk '{print $1}' > "${TMPDIR}/sha.a"
  for i in $(git reflog show | head -10 | awk '{print $2}'); do
      git rev-parse "$i"
  done >> "${TMPDIR}/sha.a"
  (cd "/cache/${cache_base}"; ls *.tar) | cut -d '.' -f1 > "${TMPDIR}/sha.b"
  # Set operation: B - A
  join -v 2 <(sort -u ${TMPDIR}/sha.a) <(sort -u ${TMPDIR}/sha.b) | while read i; do
      echo "Removing build cache: ${CACHE_VOLUME}/${i}.tar"
      rm -f "${cache_base}/${i}.tar" || :
  done
fi

mysqladmin -uroot shutdown
