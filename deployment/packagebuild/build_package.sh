#!/bin/bash
set -e
whereami="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
vnet_path=opt/axsh/wakame-vnet
etc_path=etc

pkg_format="rpm"
pkg_epoch=0

pkg_output_dir=packages/rhel/6/current
pkg_to_build=$1

fpm_path=${fpm_path:-"$vnet_path/ruby/bin/fpm"}

possible_archs="i386 noarch x86_64"

dependencies="rpmbuild createrepo"

function print_usage() {
  echo "Do not call this script directly. Use make instead with the following commands:"
  echo ""
  echo "cd $(cd $whereami/../.. && pwd)"
  echo "make build-rpm"
}

function check_path() {
  local dir=$1
  [ -d $dir ] || {
    echo "Directory '$dir' not found"
    print_usage
    exit 1
  }
}

# Resets all package metadata to present leftovers from a previously sourced package
function flush_package_meta() {
  pkg_name=""
  pkg_desc=""
  pkg_deps=""
  pkg_arch=""
  pkg_dirs=""
  pkg_cfgs=""
  pkg_owned_dirs=""
}

function build_package() {
  local pkg_meta_file=$1

  flush_package_meta
  . ${whereami}/packages.d/$pkg_meta_file

  echo "building $pkg_format package: $pkg_name"

  if [ -z "$pkg_dirs" ]; then
    pkg_src=empty
  else
    pkg_src=dir
  fi
  if [ -z "$pkg_deps" ]; then pkg_deps_string=""; else pkg_deps_string="--depends ${pkg_deps//\ / -d }"; fi
  if [ -z "$pkg_cfgs" ]; then pkg_cfgs_string=""; else pkg_cfgs_string="--config-files ${pkg_cfgs//$'\n'/ --config-files }"; fi
  if [ -z "$pkg_owned_dirs" ]; then pkg_own_string=""; else pkg_own_string="--directories ${pkg_owned_dirs//$'\n'/ --directories }"; fi

  pkg_arch_dir=$pkg_arch
  [ "$pkg_arch_dir" == "all" ] && pkg_arch_dir=noarch

  $fpm_path -s $pkg_src -t $pkg_format -n $pkg_name -p $pkg_output_dir/$pkg_arch_dir/ \
    ${pkg_deps_string} \
    ${pkg_cfgs_string} \
    ${pkg_own_string} \
    --epoch $pkg_epoch \
    --description "${pkg_desc}" \
    --architecture $pkg_arch \
    $pkg_dirs
}

check_path $vnet_path
check_path $etc_path

# Create pkg dirs
for arch in $possible_archs; do
  mkdir -p $pkg_output_dir/$arch
done

# Build pkgs
if [ -z "$pkg_to_build" ]; then
  for pkg_meta_file in `ls ${whereami}/packages.d/`; do
    build_package $pkg_meta_file
  done
else
  build_package "$pkg_to_build.meta"
fi

# Create yum repository
(cd $pkg_output_dir; createrepo .)
