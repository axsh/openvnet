#!/bin/bash
set -e
whereami="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
vnet_path="$( cd $whereami/../.. && pwd )"
etc_path=$vnet_path/deployment/conf_files/etc
pkg_format="rpm"
pkg_output_dir=$vnet_path/packages/$pkg_format
pkg_to_build=$1

function build_package() {
  local pkg_meta_file=$1

  . ${whereami}/packages.d/$pkg_meta_file

  echo "building $pkg_format package: $pkg_name"

  if [ -z "$pkg_dirs" ]; then
    pkg_src=empty
  else
    pkg_src=dir
  fi
  pkg_deps_string="-d ${pkg_deps//\ / -d }"

  #TODO: Add directory owning
  fpm -s $pkg_src -t $pkg_format -n $pkg_name -p $pkg_output_dir \
    ${pkg_deps_string} \
    --description "${pkg_desc}" \
    $pkg_dirs
}

mkdir -p $pkg_output_dir
if [ -z "$pkg_to_build" ]; then
  for pkg_meta_file in `ls ${whereami}/packages.d/`; do
    build_package $pkg_meta_file
  done
else
  build_package "$pkg_to_build.meta"
fi
