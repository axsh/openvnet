#!/bin/bash
#
# dependencies: make git gcc gcc-c++ rpm-build redhat-rpm-config rpmdevtools yum-utils python-devel openssl-devel kernel-devel-$(uname -r) kernel-debug-devel-$(uname -r)
#

set -e

package=$1
work_dir=${WORK_DIR:-/tmp/vnet-rpmbuild}
repo_base_dir=${REPO_BASE_DIR:-${work_dir}}/packages/rhel/6/third_party
repo_dir=
current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
fpm_cook_cmd=${fpm_cook_cmd:-${current_dir}/bin/fpm-cook}
possible_archs="i386 noarch x86_64"
keep_fpm_workdirs=5

function build_all_packages(){
  find ${current_dir}/packages.d/third_party -mindepth 1 -maxdepth 1 -type d | while read line; do
    build_package $(basename ${line})
  done
}

function build_package(){
  local name=$1
  local recipe_dir=${current_dir}/packages.d/third_party/${name}
  local package_work_dir=${work_dir}/packages.d/third_party/${name}
  mkdir -p ${package_work_dir}
  if [[ -f ${recipe_dir}/recipe.rb ]]; then
    (cd ${recipe_dir}; ${fpm_cook_cmd} --workdir ${package_work_dir} --no-deps)
  elif [[ -x ${recipe_dir}/rpmbuild.sh ]]; then
    ${recipe_dir}/rpmbuild.sh
  else
    echo "error: script not found: ${name}"
    exit 1
  fi
  for arch in ${possible_archs}; do
    cp ${package_work_dir}/pkg/*${arch}.rpm ${repo_dir}/${arch} | :
  done
}

function check_repo(){
  repo_dir=${repo_base_dir}/$(date +%Y%m%d%H%M%S)
  rm -rf ${repo_dir}
  mkdir -p ${repo_dir}
  for i in ${possible_archs}; do
    mkdir ${repo_dir}/${i}
  done
}

function cleanup(){
  for s in package-dir-build package-dir-staging package-rpm-build; do
    find /tmp -mindepth 1 -maxdepth 1 -type d -mtime +1 -name "${s}*" -exec rm -rf {} \;
  done
}

rm -rf ${work_dir}/packages.d/third_party
mkdir -p ${work_dir}/packages.d/third_party

check_repo

if [[ -n ${package} ]]; then
  build_package ${package}
else
  build_all_packages
fi

(cd ${repo_dir}; createrepo .)

ln -sfn ${repo_dir} ${repo_base_dir}/current

cleanup
