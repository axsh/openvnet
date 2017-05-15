#!/bin/bash
#
# dependencies: make git gcc gcc-c++ rpm-build redhat-rpm-config rpmdevtools yum-utils python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r)
#

set -e
set -x

version=$1
REPO_BASE_DIR="/repos"
current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

function build_package(){
  local version=$1
  local recipe_dir=${current_dir}/packages.d/openvnet-openvswitch
  if [[ -x ${recipe_dir}/rpmbuild.sh ]]; then
    (cd ${recipe_dir}; ./rpmbuild.sh "${version}")
  else
    echo "error: script not found: ${name}"
    exit 1
  fi
}

# sudo wrapper functions.
if [[ $(id -u) -ne 0 ]]; then
  function yum() {
    /usr/bin/sudo $(command -v yum) $*
  }

  function yum-builddep() {
    /usr/bin/sudo $(command -v yum-builddep) $*
  }
  # export these wrappers to subshell.
  export -f yum yum-builddep
fi

rpm -q rpmdevtools > /dev/null || yum install -y rpmdevtools
rpm -q createrepo > /dev/null || yum install -y createrepo

if [[ -n ${version} ]]; then
    build_package ${version}
else
  cat "${current_dir}/packages.d/openvnet-openvswitch/versions" | while read v; do
    build_package "${v}"
  done
fi

repo_dir=${REPO_BASE_DIR}/packages/rhel/6/third_party/$(date +%Y%m%d%H%M%S)
[ -d ${repo_dir} ] || mkdir -p ${repo_dir}
# Copy all rpms from rpmbuild/RPMS/*.
cp -a $(rpm -E '%{_rpmdir}')/* ${repo_dir}
(cd ${repo_dir}; createrepo .)

(cd ${repo_dir}/..; ln -sfn $(basename ${repo_dir}) current)
