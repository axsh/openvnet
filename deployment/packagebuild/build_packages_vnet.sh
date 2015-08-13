#!/bin/bash
#
# dependencies: make git gcc gcc-c++ yum-utils
#
set -e
set -x

package=$1
work_dir=${WORK_DIR:-/tmp/vnet-rpmbuild}
repo_base_dir=${REPO_BASE_DIR:-${work_dir}}/packages/rhel/6/vnet
repo_dir=
current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
fpm_cook_cmd=${fpm_cook_cmd:-${current_dir}/bin/fpm-cook}
possible_archs="i386 noarch x86_64"

# Set RPM_VERSION manually
if [[ -z ${RPM_VERSION} ]]; then
  # Jenkins currently uses internal tagging, resulting in the next line not working
  #rpm_suffix=$(git describe --tags) 
  rpm_suffix=$(echo ${BUILD_ID:-$(date +%Y%m%d%H%M%S)} | sed -e 's/[^0-9]//g')
else
  rpm_suffix=${RPM_VERSION}
fi

function build_all_packages(){
  find ${current_dir}/packages.d/vnet -mindepth 1 -maxdepth 1 -type d | while read line; do
    build_package $(basename ${line})
  done
}

function build_package(){
  local name=$1
  local recipe_dir=${current_dir}/packages.d/vnet/${name}
  local package_work_dir=${work_dir}/packages.d/vnet/${name}
  [[ -f ${recipe_dir}/recipe.rb ]] || {
    echo "error: recipe not found: ${name}"
    exit 1
  }
  mkdir -p ${package_work_dir}
  (cd ${recipe_dir}; RPM_VERSION=${rpm_suffix} ${fpm_cook_cmd} --workdir ${package_work_dir} --no-deps)
  for arch in ${possible_archs}; do
    cp ${package_work_dir}/pkg/*${arch}.rpm ${repo_dir}/${arch} | :
  done
}

function check_repo(){
  repo_dir=${repo_base_dir}/${rpm_suffix}git$(echo ${GIT_COMMIT:-spot} | cut -c-7)
  echo "$repo_dir"
  #mkdir -p ${repo_dir}
  #for i in ${possible_archs}; do
  #  mkdir -p ${repo_dir}/${i}
  #done
}

function cleanup(){
  for s in package-dir-build* package-dir-staging* package-rpm-build*; do
    find /tmp -mindepth 1 -maxdepth 1 -type d -mtime +1 -name "${s}" -print0 | xargs -0 rm -rf
  done
}

#rm -rf ${work_dir}/packages.d/vnet
#mkdir -p ${work_dir}/packages.d/vnet
#
#check_repo
#
#if [[ -n ${package} ]]; then
#  build_package ${package}
#else
#  build_all_packages
#fi
#
#(cd ${repo_dir}; createrepo .)
#
#ln -sfn ${repo_dir} ${repo_base_dir}/current
#
#cleanup

BUILD_TYPE=${BUILD_TYPE:-development}
OPENVNET_SPEC_FILE="${current_dir}/packages.d/vnet/openvnet.spec"
OPENVNET_SRC_ROOT_DIR=$( cd "${current_dir}/../.."; pwd )
WORK_DIR=${WORK_DIR:-/tmp/vnet-rpmbuild}

#
# Install dependencies
#

command -v yum-builddep >/dev/null 2>&1 || {
  sudo yum install -y yum-utils
}

if [ ! -f /opt/axsh/openvnet/ruby/bin/bundle ]; then
  #TODO: When building a stable version, make sure that we're installing the correct version of openvnet-ruby
  echo 'WARN: openvnet-ruby was not installed. Adding the OpenVNet third party repository to /etc/yum.repos.d so we can install it.'
  sudo cp "${current_dir}/../yum_repositories/${BUILD_TYPE}/openvnet-third-party.repo" /etc/yum.repos.d
fi

sudo yum-builddep "$OPENVNET_SPEC_FILE"

#
# Prepare build directories and put the source in place.
#

OPENVNET_SRC_BUILD_DIR="${WORK_DIR}/SOURCES/openvnet"
if [ -d "$OPENVNET_SRC_BUILD_DIR" ]; then
  rm -rf "$OPENVNET_SRC_BUILD_DIR"
fi

mkdir -p "${WORK_DIR}/SOURCES"
#cp -r "$OPENVNET_SRC_ROOT_DIR/" "${WORK_DIR}/SOURCES"

rm -rf "${WORK_DIR}/RPMS/*"

#
# Build the packages
#

cd ${OPENVNET_SRC_BUILD_DIR}
if [ "$BUILD_TYPE" == "stable" ]; then
  # If we're building a stable version we must make sure we checkout the correct version of the code.

  #TODO: Fail if RPM_VERSION isn't set
  git checkout "${RPM_VERSION}"
  echo "Building the following commit for stable version ${RPM_VERSION}"
  git log -n 1 --format=short

  rpmbuild -ba --define "_topdir ${WORK_DIR}" "${OPENVNET_SPEC_FILE}"
else
  # If we're building a development version we set the git commit time and hash as release
  timestamp=$(date --date="$(git show -s --format=%cd --date=iso HEAD)" +%Y%m%d%H%M%S)
  RELEASE_SUFFIX="${timestamp}git$(git rev-parse --short HEAD)"

  rpmbuild -ba --define "_topdir ${WORK_DIR}" --define "dev_release_suffix ${RELEASE_SUFFIX}" "${OPENVNET_SPEC_FILE}"
fi


#
# Prepare the yum repo
#
#check_repo
