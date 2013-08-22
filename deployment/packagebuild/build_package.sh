#!/bin/bash #
# dependencies: make git gcc gcc-c++ yum-utils
#
set -e

package=$1
work_dir=${work_dir:-/tmp/vnet-rpmbuild}
repo_dir=${repo_dir:-${work_dir}/packages/rhel/6/current}
current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
fpm_cook_cmd=${fpm_cook_cmd:-${current_dir}/bin/fpm-cook}
possible_archs="i386 noarch x86_64"

function build_all_packages(){
  find ${current_dir}/recipes -mindepth 1 -maxdepth 1 -type d | while read line; do
    build_package $(basename ${line})
  done
}

function build_package(){
  local name=$1
  local recipe_dir=${current_dir}/recipes/${name}
  [[ -f ${recipe_dir}/recipe.rb ]] || {
    echo "recipe for ${name} not found"; exit 1;
  }
  mkdir ${work_dir}/recipes/${name}
  (cd ${recipe_dir}; ${fpm_cook_cmd} --workdir ${work_dir}/recipes/${name} --no-deps)
  for arch in ${possible_archs}; do
    cp ${work_dir}/recipes/${name}/pkg/*${arch}.rpm ${repo_dir}/${arch} | :
  done
}

rm -rf ${work_dir}/recipes
mkdir ${work_dir}/recipes
mkdir -p ${repo_dir}

if [[ -n ${package} ]]; then
  build_package ${package}
else
  build_all_packages
fi

(cd ${repo_dir}; createrepo .)
