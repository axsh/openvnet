#!/bin/bash
#
# dependencies: make git gcc gcc-c++ yum-utils fakeroot fakechroot
#
set -e

package=$1
work_dir=${work_dir:-/tmp/vnet-rpmbuild}
repo_dir=${repo_dir:-${work_dir}/packages/rhel/6/current}
chroot_dir=${work_dir}/chroot
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

function prepare_chroot_env(){
  umount_for_chroot
  rm -rf ${chroot_dir}
  mkdir ${chroot_dir}
  mkdir ${chroot_dir}/repo
  mkdir -p ${chroot_dir}/var/lib/rpm
  rpm --root ${chroot_dir} --initdb
  yumdownloader --destdir=/var/tmp centos-release
  cd /var/tmp
  rpm --root ${chroot_dir} -ivh --nodeps centos-release*rpm
  yum --installroot=${chroot_dir} -y install rpm-build yum
  rpm --root ${chroot_dir} -ivh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release
  cp ${chroot_dir}/etc/skel/.??* ${chroot_dir}/root/
  cp /etc/resolv.conf ${chroot_dir}/etc/
  cat <<EOS > ${chroot_dir}/etc/yum.repos.d/wakame-vnet.repo
[wakame-vnet]
name=Wakame-Vnet
baseurl=file:///repo
enabled=1
gpgcheck=0
EOS
  mount_for_chroot
}

function mount_for_chroot(){
  mount --rbind /dev ${chroot_dir}/dev
  mount -t proc none ${chroot_dir}/proc
  mount --rbind /sys ${chroot_dir}/sys
  mount --rbind ${repo_dir} ${chroot_dir}/repo
}

function umount_for_chroot(){
  umount -l ${chroot_dir}/dev | :
  umount ${chroot_dir}/proc | :
  umount -l ${chroot_dir}/sys | :
  umount -l ${chroot_dir}/repo | :
}

function install_test(){
  fakeroot fakechroot /usr/sbin/chroot ${chroot_dir}/ yum install -y wakame-vnet
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

if [[ -z ${package} ]]; then
  #trap "umount_for_chroot" ERR
  prepare_chroot_env
  install_test
  umount_for_chroot
fi
