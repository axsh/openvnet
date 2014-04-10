#!/bin/bash
#
# dependencies: yum-utils
#
set -e

work_dir=${WORK_DIR:-/tmp/vnet-rpmbuild}
vnet_repo_dir=${REPO_BASE_DIR:-${work_dir}}/packages/rhel/6/vnet/current
third_party_repo_dir=${REPO_BASE_DIR:-${work_dir}}/packages/rhel/6/third_party/current
chroot_dir=${work_dir}/chroot
chroot_cache_dir=${work_dir}/chroot_cache
clear_chroot_cache=${CLEAR_CHROOT_CACHE}

centos_version=${CENTOS_VERSION:-6-5}

function prepare_chroot_env(){
  umount_for_chroot
  rm -rf ${chroot_dir}
  echo ${clear_chroot_cache}
  [[ ${clear_chroot_cache} = "true" ]] || [[ ! -d ${chroot_cache_dir} ]] && create_chroot_cache
  cp -a ${chroot_cache_dir} ${chroot_dir}
  mount_for_chroot
}

function mount_for_chroot(){
  mount --rbind /dev ${chroot_dir}/dev
  mount -t proc none ${chroot_dir}/proc
  mount --rbind /sys ${chroot_dir}/sys
  mount --bind ${vnet_repo_dir} ${chroot_dir}/repo/vnet
  mount --bind ${third_party_repo_dir} ${chroot_dir}/repo/third_party
}

function umount_for_chroot(){
  umount -l ${chroot_dir}/dev | :
  umount ${chroot_dir}/proc | :
  umount -l ${chroot_dir}/sys | :
  umount -l ${chroot_dir}/repo/vnet | :
  umount -l ${chroot_dir}/repo/third_party | :
}

function create_chroot_cache(){
  echo "creating chroot cache"
  rm -rf ${chroot_cache_dir}
  mkdir -p ${chroot_cache_dir}
  mkdir ${chroot_cache_dir}/repo
  mkdir ${chroot_cache_dir}/repo/vnet
  mkdir ${chroot_cache_dir}/repo/third_party
  mkdir -p ${chroot_cache_dir}/var/lib/rpm
  rpm --root ${chroot_cache_dir} --initdb
  yumdownloader --destdir=/var/tmp centos-release
  cd /var/tmp
  rpm --root ${chroot_cache_dir} -ivh --nodeps centos-release-${centos_version}*rpm
  cp /etc/fstab ${chroot_cache_dir}/etc/
  touch ${chroot_cache_dir}/var/lib/random-seed
  yum --installroot=${chroot_cache_dir} -y install rpm-build yum kernel-$(uname -r)
  rpm --root ${chroot_cache_dir} -ivh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release
  cp ${chroot_cache_dir}/etc/skel/.??* ${chroot_cache_dir}/root/
  cp /etc/resolv.conf ${chroot_cache_dir}/etc/
  cp /etc/hosts ${chroot_cache_dir}/etc/
  cat <<EOS > ${chroot_cache_dir}/etc/yum.repos.d/openvnet.repo
[openvnet]
name=OpenVNet
baseurl=file:///repo/vnet/
enabled=1
gpgcheck=0
EOS
  cat <<EOS > ${chroot_cache_dir}/etc/yum.repos.d/openvnet-third-party.repo
[openvnet-third-party]
name=OpenVNet-Third-Party
baseurl=file:///repo/third_party/
enabled=1
gpgcheck=0
EOS
}

function install_rpm(){
  chroot ${chroot_dir}/ yum install -y openvnet
}

#trap "umount_for_chroot" ERR
prepare_chroot_env
install_rpm
umount_for_chroot
