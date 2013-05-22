#!/bin/bash
set -e
whereami="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
vnet_path="$( cd $whereami/../.. && pwd )"
pkg_format="rpm"

for pkg_meta_file in `ls ${whereami}/packages.d/`; do
  . ${whereami}/packages.d/$pkg_meta_file

  echo "building $pkg_format package: $pkg_name"
  fpm -s dir -t $pkg_format -n $pkg_name \
    --description "$pkg_desc" \
    --directories $pkg_dirs \
    $pkg_dirs
done
