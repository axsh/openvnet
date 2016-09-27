#!/bin/bash
#
# dependencies: make git gcc gcc-c++ rpm-build redhat-rpm-config rpmdevtools yum-utils python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r)
#

set -e
set -x

package=$1
REPO_BASE_DIR="${REPO_BASE_DIR:-/var/www/html/repos}"
current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

function build_all_packages(){
  find ${current_dir}/packages.d/third_party -mindepth 1 -maxdepth 1 -type d | while read line; do
    build_package $(basename ${line})
  done
}

function build_package(){
  local name=$1
  local recipe_dir=${current_dir}/packages.d/third_party/${name}
  if [[ -x ${recipe_dir}/rpmbuild.sh ]]; then
    (cd ${recipe_dir}; ./rpmbuild.sh)
  else
    echo "error: script not found: ${name}"
    exit 1
  fi
}

rpm -q rpmdevtools > /dev/null || yum install -y rpmdevtools
rpm -q createrepo > /dev/null || yum install -y createrepo
rpmdev-wipetree

if [[ -n ${package} ]]; then
  build_package ${package}
else
  build_all_packages
fi

repo_dir=${REPO_BASE_DIR}/packages/rhel/6/third_party/$(date +%Y%m%d%H%M%S)
[ -d ${repo_dir} ] || mkdir -p ${repo_dir}
# Copy all rpms from rpmbuild/RPMS/*.
cp -a $(rpm -E '%{_rpmdir}')/* ${repo_dir}
(cd ${repo_dir}; createrepo .)

(cd ${repo_dir}/..; ln -sfn $(basename ${repo_dir}) current)
