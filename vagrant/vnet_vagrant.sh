#!/bin/bash

set -e
set -x

install() {
  vagrant up

  [[ -f ${ssh_key} ]] || prepare_ssh_key

  ./ssh_config.rb -y

  for node in $vnet_vms ; do
    bundle exec knife solo prepare ${node}
  done

  bundle exec berks install --path cookbooks

  update
}

update() {
  for node in $vnet_vms ; do
    bundle exec knife solo cook ${node}
  done
}

prepare_ssh_key() {
  local private_key=${1-~/.vagrant.d/insecure_private_key}

  mkdir -p ${ssh_dir}
  cp ${private_key} ${ssh_key}
  ssh-keygen -y -f ${ssh_dir}/id_rsa > ${ssh_dir}/authorized_keys
}

cd $(dirname ${BASH_SOURCE[0]})

ssh_dir=$(dirname $0)/vm/ssh
ssh_key=${ssh_dir}/id_rsa

command=$1

vnet_vms="
vnmgr
vna1
vna2
vna3
edge
legacy
router
"
case $command in

prepare_ssh_key)
  prepare_ssh_key $1
  ;;

install)
  install
  ;;

*|update)
  update
  ;;

esac
